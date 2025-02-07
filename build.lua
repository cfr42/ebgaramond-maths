-- $Id: build.lua 10780 2025-02-07 08:15:26Z cfrees $
-------------------------------------------------
-- Build configuration for ebgaramond-maths
-------------------------------------------------
-- l3build.pdf listing 1 tudalen 9
-- ref. https://tex.stackexchange.com/questions/720446/how-can-i-export-variables-to-the-environment-when-running-l3build?noredirect=1#comment1791863_720446
-------------------------------------------------
sourcefiledir = "."
maindir = "." 
bakext = ".bkup"
ctanpkg = "ebgaramond-maths"
module = "ebgaramond-maths"
texmfdir = maindir .. "/texmf"
require(kpse.lookup("fntbuild.lua"))
fnt.buildsuppfiles_sys = { "EBGaramond-Italic.otf", "EBGaramond-BoldItalic.otf", "EBGaramond-ExtraBoldItalic.otf", "EBGaramond-MediumItalic.otf", "EBGaramond-SemiBoldItalic.otf" }
-- fnt.autotestfds = {  "ly1ybd.fd", "ly1ybd2.fd", "ly1ybd2j.fd", "ly1ybd2jw.fd", "ly1ybd2w.fd", "ly1ybdj.fd", "ly1ybdjw.fd", "ly1ybdw.fd", "t1ybd.fd", "t1ybd2.fd", "t1ybd2j.fd", "t1ybdj.fd" }
-- fnt.keepfiles = { "ybd.map", "*.afm", "*.pfb", "*.tfm" , "ts1ybd2w.fd", "ts1ybd2jw.fd", "ts1ybdjw.fd", "ts1ybdw.fd" }
-- fnt.keeptempfiles = { "*.pl" }
-- dofile(maindir .. "/fontscripts/fntbuild.lua")
-- checkdeps = {maindir .. "/nfssext-cfr", maindir .. "/fontscripts"}
ctanreadme = "README.md"
-- demofiles = {"*-example.tex"}
-- flatten = true
-- flattentds = false
manifestfile = "manifest.txt"
-- packtdszip = false
tagfiles = {"*.dtx", "*.ins", "manifest.txt", "MANIFEST.txt", "README", "README.md"}
-- typesetdeps = {maindir .. "/nfssext-cfr", maindir .. "/fontscripts"}
-- typesetsourcefiles = {fnt.keepdir .. "/*", "nfssext-cfr*.sty"}
-- unpackexe = "pdflatex"
-- unpackfiles = {"*.ins"}
-------------------------------------------------
-- fnt.builddeps = { maindir .. "/fontscripts" } 
fnt.checksuppfiles_add = {
  "/fonts/enc/dvips/ebgaramond",
  "/fonts/tfm/public/ebgaramond",
  "/fonts/type1/public/ebgaramond",
  "/tex/latex/ebgaramond",
  -- "/fonts/enc/dvips/lm",
  -- "/fonts/tfm/public/lm",
  -- "/fonts/type1/public/lm",
  -- "etoolbox.sty",
  -- "ly1enc.def",
  -- "ly1enc.dfu",
  -- "ly1lmr.fd",
  -- "ly1lmss.fd",
  -- "ly1lmtt.fd",
  -- "omllmm.fd",
  -- "omllmr.fd",
  -- "omslmr.fd",
  -- "omslmsy.fd",
  -- "omxlmex.fd",
  -- "ot1lmr.fd",
  -- "ot1lmss.fd",
  -- "ot1lmtt.fd",
  "svn-prov.sty",
  -- "ts1lmdh.fd",
  -- "ts1lmr.fd",
  -- "ts1lmss.fd",
  -- "ts1lmssq.fd",
  -- "ts1lmtt.fd",
  -- "ts1lmvtt.fd",
}
-------------------------------------------------
-- START doc fntebgm
local function fntebgm (dir,mode)
  dir = dir or fnt.fntdir
  mode = mode or "errorstopmode --halt-on-error"
  local oml = "oml-ebgaramond.enc"
  local tmp = "ete.tex"
  local mapfile = "EBGaramond-Maths.map"
  -- set up the build environment
  assert(fnt.buildinit(), "Setting up build environment failed!")
  -- save dir and 'home'
  local gohome = abspath(".")
  local origdir = dir
  -- change to build dir
  assert(lfs.chdir(dir), "Could not switch to " .. dir .. "!")
  dir = "."
  local ete = [[
  \input finstmsc.sty
  \etxtoenc{oml}{oml-ebgaramond}
  \bye
  ]]
  local f = assert(io.open(tmp, "w"),"Opening " .. tmp .. " for writing failed!")
  f:write((string.gsub(ete,"\n",fnt.os_newline_cp)))
  f:close()
  assert(run(dir, "fontinst " .. tmp), "Could not create input encoding!")
  f = assert(io.open(oml, "rb"),"Cannot read " .. oml .. "!")
  local content = f:read("*all")
  f:close()
  local new_content = string.gsub(content, "TeXMathItalicEncoding", "EBGaramondTeXMathItalicEncoding")
  new_content = string.gsub(new_content, "oldstyle", "")
  new_content = string.gsub(new_content, "^/mu", "/uni000B5")
  f = assert(io.open(oml,"w"))
  f:write((string.gsub(new_content,"\n",fnt.os_newline_cp)))
  f:close()
  local m = ""
  for _,i in ipairs(fnt.buildsuppfiles_sys) do
    local out = assert(io.popen("otftotfm -e " .. oml .. " " .. i, r),"otftotfm failed for " .. i .. "!")
    f = assert(io.input(out, "rb"),"Reading map line failed for " .. i .. "!")
    m = m .. f:read("*all")
    f:close()
  end
  assert(rm(dir,oml), "Could not remove input encoding!")
  local encs = filelist(dir,"a_*.enc")
  local n = 0
  for _,i in ipairs(encs) do
    n = n + 1
    f = assert(io.open(i, "rb"),"Failed to open " .. i .. "!")
    content = f:read("*all")
    f:close()
    if string.match(content,"AutoEnc_") then
      print("Aardvarks!")
      new_content = string.gsub(content, "(AutoEnc_)[a-z0-9][a-z0-9]*", "%1EBGaramond_Maths_" .. n)
    end
    local a = string.gsub(oml,"%.enc","-" .. n .. ".enc")
    print(a)
    f = assert(io.open(a, "w"),"Could not open " .. a .. " for writing!")
    f:write((string.gsub(new_content,"\n",fnt.os_newline_cp)))
    f:close()
    rm(dir, i)
    if fileexists(i) then
      print("Warning: Could not remove " .. i "!")
    end
    m = string.gsub(m, i, a)
    m = string.gsub(m, "(AutoEnc_)[a-z0-9][a-z0-9]*", "%1EBGaramond_Maths_" .. n)
  end
  f = assert(io.open(mapfile, "w"),"Failed to open " .. mapfile .. " for writing!")
  f:write((string.gsub(m,"\n",fnt.os_newline_cp)))
  f:close()
  if fileexists(dir .. "/pdftex.map") then rm(dir,"pdftex.map") end
  -- return home
  assert(lfs.chdir(gohome), "Could not switch to " .. gohome .. "!")
  dir = origdir
  -- call fnt.fntkeeper() to save the build results into fnt.keepdir else
  -- l3build deletes them before testing or compilation!
  assert(fnt.fntkeeper(),"FONT KEEPER FAILED IN " .. dir .. "! DO NOT MAKE STANDARD TARGETS WITHOUT RESOLVING!! ")
  return 0
end
-- make local function available in table ebgm
ebgm = {}
ebgm.fntebgm = fntebgm
-- redefine fnt.ntarg so that fnttarg calls ebgm.fntebgm rather than fontinst
target_list[fnt.ntarg] = {
  func = ebgm.fntebgm,
  desc = "Creates TeX font files",
  pre = function(names)
    if names then
      print("fntebgm does not need names\n")
      help()
      exit(1)
    end
    return 0
  end
}
-- STOP doc fntebgm
-------------------------------------------------
-- unpackdeps = {maindir .. "/fontscripts"}
textfiles = {"*.md", "*.txt"}
typesetruns = 1
-------------------------------------------------
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
	author     = "Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/ebgaramond-maths",
	license    = {"lppl1.3c"},
	pkg        = ctanpkg,
	summary    = "Limited support for ebgaramond in maths",
  uploader   = "Clea F. Rees",
	version    = "v0.0",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/ebgaramond-maths/issues"},
  -- description
  -- development {}
  -- home {}
	repository = {"https://codeberg.org/cfr/ebgaramond-maths", "https://github.com/cfr42/ebgaramond-maths"},
	note = "Repository mirrored at https://github.com/cfr42/ebgaramond-maths",
	-- repository = "https://codeberg.org/cfr/ebgaramond-maths",
  -- support {}
	topic      = {"font", "font-type1", "font-serif"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
-------------------------------------------------
date = "2014-2025"
if fileexists(maindir .. "/nfssext/fnt-manifest.lua") then
  dofile(maindir .. "/nfssext/fnt-manifest.lua")
end
if fileexists(maindir .. "/nfssext/tag.lua") then
  dofile(maindir .. "/nfssext/tag.lua")
end
-------------------------------------------------
-- vim: ts=2:sw=2:tw=80:nospell
