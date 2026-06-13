return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft", "TmuxNavigateDown",
      "TmuxNavigateUp", "TmuxNavigateRight",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>",  desc = "Pane left" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>",  desc = "Pane down" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>",    desc = "Pane up" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Pane right" },
    },
  },
}
