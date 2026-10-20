local markdown_list = require("core.markdown_list")

describe("markdown list continuation", function()
  local function assert_next(line, expected_prefix, expected_clear)
    local prefix, clear = markdown_list.next_item(line)
    assert.are.equal(expected_prefix, prefix)
    assert.are.equal(expected_clear, clear)
  end

  it("continues unordered lists with the same marker and indentation", function()
    assert_next("- first", "- ", nil)
    assert_next("  * nested", "  * ", nil)
    assert_next("+ another", "+ ", nil)
  end)

  it("increments ordered lists", function()
    assert_next("1. first", "2. ", nil)
    assert_next("  9) nested", "  10) ", nil)
  end)

  it("continues checkboxes as unchecked", function()
    assert_next("- [ ] todo", "- [ ] ", nil)
    assert_next("- [x] done", "- [ ] ", nil)
    assert_next("3. [X] done", "4. [ ] ", nil)
  end)

  it("clears an empty list item to end the list", function()
    assert_next("- ", nil, "")
    assert_next("  - [ ] ", nil, "  ")
    assert_next("4. ", nil, "")
  end)

  it("ignores normal text", function()
    assert_next("paragraph", nil, nil)
    assert_next("-not a list", nil, nil)
  end)
end)

describe("markdown list enter integration", function()
  before_each(function()
    vim.cmd("enew!")
    vim.bo.filetype = "markdown"
  end)

  it("returns the newline and next marker synchronously", function()
    vim.api.nvim_set_current_line("- first")

    local keys = markdown_list.continue_list()

    assert.are.equal(vim.api.nvim_replace_termcodes("<CR>- ", true, false, true), keys)
    assert.are.equal("- first", vim.api.nvim_get_current_line())
  end)

  it("returns backspaces without changing the buffer inside an expression mapping", function()
    vim.api.nvim_set_current_line("  - ")

    local keys = markdown_list.continue_list()

    assert.are.equal(vim.api.nvim_replace_termcodes("<BS><BS>", true, false, true), keys)
    assert.are.equal("  - ", vim.api.nvim_get_current_line())
  end)
end)
