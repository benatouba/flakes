require('user-defaults')
require('functions')
require('keymappings')
require('user-settings')
require('settings')
pcall(require, 'impatient')
require('plugins')
require('base')
require('autocommands')
if Exists(O.packer_compile_path) then
  require('packer_compiled')
end
require('colorscheme')
