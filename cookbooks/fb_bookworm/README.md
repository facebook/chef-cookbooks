fb_bookworm
===========

Bookworm is a program that gleans context from a Chef/Ruby codebase, which
recognizes that Ruby source files in different directories have different
semantic meaning to a larger program (ie Chef)

It currently runs on top of the Chef Workstation Ruby, although there is
nothing preventing running bookworm on vanilla Ruby using bundler, etc.

Running bookworm
----------------

Bookworm is designed to be installed via Chef cookbook, as well as the ability
to be run directly from the cookbook.

Implementation notes - Why Rubocop for AST generation
-----------------------------------------------------

Because we wanted to use something that was already in Chef Workstation, the
two choices were Ripper or Parser a la RuboCop (ruby_parser uses racc which has
a C extension, but no sexp pattern matcher that I know of).

Ripper is fast, but the sexp output is kind of nasty, and cleaning that up
could be a big timesuck. Since the larger Ruby/Chef community has a bit more
familiarity with Parser/RuboCop's node pattern matching, it'd be better to stay
with that for now (there's no reason this couldn't be migrated later with
helpers to translate patterns). Work could also be done to speed up RuboCop
(ractor and async support could go a long way here).
