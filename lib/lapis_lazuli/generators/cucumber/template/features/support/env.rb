################################################################################
# Copyright <%= config[:year] %> spriteCloud B.V. All rights reserved.
# Generated by LapisLazuli, version <%= config[:lapis_lazuli][:version] %>
# Author: "<%= config[:user] %>" <<%= config[:email] %>>
require 'lapis_lazuli'
require 'lapis_lazuli/cucumber'

ll = LapisLazuli::LapisLazuli.instance
ll.init("config/config.yml");