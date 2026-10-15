#!/usr/bin/env python3
"""Exercise skills installation with a local Git remote and disposable homes."""
import os
from pathlib import Path
import subprocess
import tempfile

SOURCE = Path(__file__).resolve().parents[1]
INSTALLER = SOURCE / 'codex/install.sh'
URL = 'https://github.com/sorafujitani/skills.git'


def run(args, *, env=None, cwd=None, ok=True):
    result = subprocess.run(args, env=env, cwd=cwd, text=True, capture_output=True)
    assert (result.returncode == 0) == ok, (args, result.stdout, result.stderr)
    return result.stdout.strip()


# Reuse the developer's configured identity for fixture commits.
identity = {key: run(['git', 'config', key], cwd=SOURCE)
            for key in ('user.name', 'user.email')}
with tempfile.TemporaryDirectory(prefix='codex-skills-test-') as tmp:
    root = Path(tmp)
    remote = root / 'remote'
    run(['git', 'init', '-q', '-b', 'main', str(remote)])
    for key, value in identity.items():
        run(['git', '-C', str(remote), 'config', key, value])
    for name in ('example', 'conflict', 'legacy', 'broken'):
        (remote / name / 'references').mkdir(parents=True)
        (remote / name / 'SKILL.md').write_text(
            f'---\nname: {name}\ndescription: Fixture skill\n---\nTest\n')
        (remote / name / 'references/detail.md').write_text('version one\n')
    (remote / 'ordinary-directory').mkdir()
    (remote / 'ordinary-directory/file').write_text('not a skill\n')
    run(['git', '-C', str(remote), 'add', '.'])
    run(['git', '-C', str(remote), 'commit', '-qm', 'Initial fixture'])

    home = root / 'home with spaces'
    home.mkdir()
    env = dict(os.environ, HOME=str(home), CODEX_HOME=str(home / 'custom codex'),
               GIT_CONFIG_GLOBAL=str(root / 'gitconfig'), GIT_CONFIG_NOSYSTEM='1')
    # Exercise real clone/fetch/merge without network access.
    run(['git', 'config', '--global', f'url.file://{remote}.insteadOf', URL], env=env)
    checkout = home / 'ghq/github.com/sorafujitani/skills'
    discovery = home / '.agents/skills'
    config = Path(env['CODEX_HOME']) / 'config.toml'

    def install(*args, ok=True):
        return run(['sh', str(INSTALLER), *args], env=env, ok=ok)

    install('--skills-only', '--dry-run')
    assert not checkout.exists() and not discovery.exists() and not config.exists()
    (discovery / 'conflict').mkdir(parents=True)
    (discovery / 'conflict/SKILL.md').write_text('preserve custom skill')
    (discovery / 'broken').symlink_to(home / 'missing-external')
    (Path(env['CODEX_HOME']) / 'skills/legacy').mkdir(parents=True)
    config.write_text('preserve config')
    install('--skills-only')
    assert config.read_text() == 'preserve config'
    assert (discovery / 'example').is_symlink()
    assert (discovery / 'example/references/detail.md').read_text() == 'version one\n'
    assert (discovery / 'conflict/SKILL.md').read_text() == 'preserve custom skill'
    assert os.readlink(discovery / 'broken') == str(home / 'missing-external')
    assert not (discovery / 'legacy').exists()
    assert not (discovery / 'ordinary-directory').exists()
    install('--skills-only')

    (remote / 'example/references/detail.md').write_text('version two\n')
    (remote / 'new-skill').mkdir()
    (remote / 'new-skill/SKILL.md').write_text('---\nname: new-skill\ndescription: Fixture\n---\n')
    run(['git', '-C', str(remote), 'add', '.'])
    run(['git', '-C', str(remote), 'commit', '-qm', 'Update fixture'])
    # Config matches, but skills must still update.
    config.write_bytes((SOURCE / 'codex/config.toml').read_bytes())
    install()
    assert (discovery / 'example/references/detail.md').read_text() == 'version two\n'
    assert (discovery / 'new-skill').is_symlink()
    assert not list(config.parent.glob('*.dotfiles-backup.*'))

    config.write_text('keep on failure')
    (checkout / 'example/SKILL.md').write_text('local edit')
    install(ok=False)
    assert config.read_text() == 'keep on failure'
    assert (checkout / 'example/SKILL.md').read_text() == 'local edit'
    run(['git', '-C', str(checkout), 'restore', 'example/SKILL.md'])
    run(['git', '-C', str(checkout), 'switch', '-c', 'local-work'])
    install('--skills-only', ok=False)
    run(['git', '-C', str(checkout), 'switch', 'main'])
    # Local commits are not silently overwritten or published.
    for key, value in identity.items():
        run(['git', '-C', str(checkout), 'config', key, value])
    run(['git', '-C', str(checkout), 'commit', '--allow-empty', '-qm', 'Local work'])
    local_head = run(['git', '-C', str(checkout), 'rev-parse', 'HEAD'])
    install('--skills-only', ok=False)
    assert run(['git', '-C', str(checkout), 'rev-parse', 'HEAD']) == local_head
    install('--skills-only', '--without-skills', ok=False)

    # Failed clone cleans its staging area and preserves the config.
    env['HOME'] = str(root / 'failed home')
    env['CODEX_HOME'] = str(root / 'failed home/.codex')
    Path(env['CODEX_HOME']).mkdir(parents=True)
    failed_config = Path(env['CODEX_HOME']) / 'config.toml'
    failed_config.write_text('keep on clone failure')
    run(['git', 'config', '--global', '--unset-all', f'url.file://{remote}.insteadOf'], env=env)
    run(['git', 'config', '--global', f'url.file://{root}/missing.insteadOf', URL], env=env)
    install(ok=False)
    assert failed_config.read_text() == 'keep on clone failure'
    assert not list((Path(env['HOME']) / 'ghq/github.com/sorafujitani').glob('.skills.*'))

print('PASS: skills dry-run, clone, support files, repeat, update, config match, conflicts, dirty checkout, branch, local commits, clone failure')
