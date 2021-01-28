# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2021-present, Facebook, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['fb_readline'] = {
  'config' => {
    'key_bindings' => {},
    'variables' => {
      'meta-flag' => true,
      'input-meta' => true,
      'convert-meta' => false,
      'output-meta' => true,
      # Completed names which are symbolic links to directories have a slash
      # appended.
      'mark-symlinked-directories' => true,
    },
    'mode' => {
      'emacs' => {
        'key_bindings' => {
          # for linux console and RH/Debian xterm
          '\e[1~' => 'beginning-of-line',
          '\e[4~' => 'end-of-line',
          '\e[5~' => 'history-search-forward',
          '\e[6~' => 'history-search-backward',
          '\e[3~' => 'delete-char',
          '\e[2~' => 'quoted-insert',
          '\e[5C' => 'forward-word',
          '\e[5D' => 'backward-word',
          '\e[1;5C' => 'forward-word',
          '\e[1;5D' => 'backward-word',
          # for rxvt
          '\e[8~' => 'end-of-line',
          '\eOc' => 'forward-word',
          '\eOd' => 'backward-word',

          # for non RH/Debian xterm, can't hurt for RH/Debian xterm
          '\eOH' => 'beginning-of-line',
          '\eOF' => 'end-of-line',

          # for FreeBSD console
          '\e[H' => 'beginning-of-line',
          '\e[F' => 'end-of-line',
        },
        'variables' => {},
      },
    },
    'term' => {},
  },
}
