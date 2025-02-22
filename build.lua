-- $Id: build.lua 10828 2025-02-20 01:58:11Z cfrees $
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
-- angen TEXMFHOME=./texmf (os ni ngosodir fontscripts)
require(kpse.lookup("fntbuild.lua"))
local otftotfm = {}
---@description otfs to convert
otftotfm.otfs = { "EBGaramond-Italic.otf", "EBGaramond-BoldItalic.otf", "EBGaramond-ExtraBoldItalic.otf", "EBGaramond-MediumItalic.otf", "EBGaramond-SemiBoldItalic.otf" }
---@description input encs to generate
otftotfm.encs = "oml-ebgaramond.enc"
---@description etx to convert
otftotfm.srcencs = { oml = "oml-ebgaramond"  }
---@description map file to generate
otftotfm.mapfile = "EBGaramond-Maths.map"
-- we're not using fontinst for the tfms etc., but we want these to create the
-- input encoding
-- fnt.buildsuppfiles_sys =  { "mathit.mtx", "oml.etx" }
-- the otfs we need for sandboxed build are part of dist
if #fnt.buildsuppfiles_sys == 0 then
  for _,i in ipairs(otftotfm.otfs) do
    table.insert(fnt.buildsuppfiles_sys,i)
  end
end
-- needed for sandboxed checking
ctanreadme = "README.md"
-- demofiles = {"*-example.tex"}
manifestfile = "manifest.txt"
tagfiles = {"*.dtx", "*.ins", "manifest.txt", "MANIFEST.txt", "README", "README.md"}
-------------------------------------------------
-- non-standard templates
checksuppfiles={"fnt-testtemp-ebgaramond.lvt","fnt-regression-test-ebgaramond.tex"}
-- additional files from dist for sandboxed checking
fnt.checksuppfiles_add = {
  "/fonts/enc/dvips/ebgaramond",
  "/fonts/tfm/public/amsfonts/cmextra",
  "/fonts/tfm/public/amsfonts/symbols",
  "/fonts/tfm/public/ebgaramond",
  "/fonts/type1/public/amsfonts/cmextra",
  "/fonts/type1/public/amsfonts/symbols",
  "/fonts/type1/public/ebgaramond",
  "/tex/generic/iftex",
  "/tex/latex/amsfonts",
  "/tex/latex/ebgaramond",
  "/tex/latex/fontaxes",
  "/tex/latex/xkeyval",
  "/tex/generic/xkeyval",
  "svn-prov.sty",
  "textcomp.sty",
}
fnt.keepfiles = {"*.enc", "*.fd", "*.map", "*.tfm" }
fnt.mapfiles_add = { "EBGaramond.map" }
-- non-standard test templates
fnt.testtemp = "fnt-testtemp-ebgaramond.lvt"
fnt.regress = "fnt-regression-test-ebgaramond.tex"
-------------------------------------------------
-- otf2tfm {{{
-- START doc fntebgm
local function otf2tfm (mapfile,dir)
  dir = dir or fnt.fntdir
  local otfs = otftotfm.otfs or filelist(dir,"*.otf")
  local encs = otftotfm.encs or filelist(dir,"*.enc")
  local opts = otftotfm.opts or ""
  local t = otfs
  local tencs = {}
  local tb = {}
  tb.encs = encs
  tb.opts = opts 
  for n,i in ipairs(otfs) do
    -- print(i)
    otfs[i] = tb 
    for _,j in ipairs(encs) do
      tencs[j] = tencs[j] or {}
      table.insert(tencs[j],i)
    end
    t[n] = nil
    otfs[n] = nil
  end
  for i,j in pairs(t) do
    if type(j) ~= "table" then
      if type(j) == "string" then
        if string.match(j,"%.enc$") then
          print("Using default options for " .. i .. ".")
          otfs[i] = { encs = j, opts = opts }
          tencs[j] = tencs[j] or {}
          table.insert(tencs[j],i)
        else
          print("Using default encodings for " .. i .. ".")
          otfs[i] = { encs = encs, opts = j }
          for _,k in ipairs(encs) do
            tencs[k] = tencs[k] or {}
            table.insert(tencs[k],i)
          end
        end
      else
        error("Expected string or table for " .. i .. " but found " .. type(j) .. "!")
      end
    else
      if j.encs == nil then
        otfs[i].encs = encs
        for _,k in ipairs(encs) do
          tencs[k] = tencs[k] or {}
          table.insert(tencs[k],i)
        end
        print("Using default encodings for " .. i .. ".")
      else
        for _,k in ipairs(j.encs) do
          tencs[k] = tencs[k] or {}
          table.insert(tencs[k],i)
        end
      end
      if j.opts == nil then
        otfs[i].opts = opts
        print("Using default options for " .. i .. ".")
      end
    end
  end
  local m = ""
  local n = 0
  for e,t in pairs(tencs) do
    n = n + 1
    for _,i in ipairs(t) do
      local out = assert(io.popen("otftotfm -e " .. e .. " " .. otfs[i].opts .. " " .. i, r),"otftotfm failed for " .. i .. "/" .. e .. " with options " .. otfs[i].opts .. "!")
      f = assert(io.input(out, "rb"),"Reading map line failed for " .. i .. "/" .. e .. " with options " .. otfs[i].opts ..  "!")
      m = m .. f:read("*all")
      f:close()
    end
    assert(rm(dir,e), "Could not remove input encoding " .. e .. "!")
    local a = filelist(dir,"a_*.enc")
    local eb = string.gsub(basename(e),"%.enc$","")
    local eb = string.gsub(eb,"-","_")
    local en = string.gsub(e,"%.enc","-" .. n .. ".enc")
    for _,i in ipairs(a) do
      f = assert(io.open(i, "rb"),"Failed to open " .. i .. "!")
      content = f:read("*all")
      f:close()
      if string.match(content,"AutoEnc_") then
        new_content = string.gsub(content, "(AutoEnc_)[a-z0-9][a-z0-9]*", "%1" .. eb .. "_" .. n)
      end
      f = assert(io.open(en, "w"),"Could not open " .. en .. " for writing!")
      f:write((string.gsub(new_content,"\n",fnt.os_newline_cp)))
      f:close()
      rm(dir, i)
      if fileexists(i) then
        print("Warning: Could not remove " .. i "!")
      end
      m = string.gsub(m, i, en)
      m = string.gsub(m, "(AutoEnc_)[a-z0-9][a-z0-9]*", "%1" .. eb .. "_" .. n)
    end
  end
  f = assert(io.open(mapfile, "w"),"Failed to open " .. mapfile .. " for writing!")
  f:write((string.gsub(m,"\n",fnt.os_newline_cp)))
  f:close()
end
fnt.otfdir = sourcefiledir 
fnt.encdir = sourcefiledir 
local function fntebgm (dir,mode)
  dir = dir or fnt.fntdir
  mode = mode or "errorstopmode --halt-on-error"
  -- lists if undefined
  if #otftotfm.otfs == 0 then
    otftotfm.otfs = filelist(fnt.otfdir, "*.otf")
    if #otftotfm.otfs == 0 then
      error("Could not find source otfs!")
    end
  end
  if type(otftotfm.encs) == "string" then 
    otftotfm.encs = { otftotfm.encs } 
  end
  if #otftotfm.encs == 0 then
    otftotfm.encs = filelist(fnt.encdir, "*.enc")
  end
  otftotfm.opts = otftotfm.opts or ""
  local tmp = "ete.tex"
  -- set up the build environment
  fnt.buildinit()
  assert(fnt.buildinit(), "Setting up build environment failed!")
  -- save dir and 'home'
  local gohome = abspath(".")
  local origdir = dir
  -- change to build dir
  assert(lfs.chdir(dir), "Could not switch to " .. dir .. "!")
  dir = "."
  -- convert source .etx to input .enc
  for i,j in pairs(otftotfm.srcencs) do
    local ete = "\\input finstmsc.sty" .. fnt.os_newline_cp ..
    "\\etxtoenc{" .. i .. "}{" .. j .. "}" .. fnt.os_newline_cp ..
    "\\bye" .. fnt.os_newline_cp
    local f = assert(io.open(tmp, "w"),"Opening " .. tmp .. " for writing failed!")
    f:write(ete)
    f:close()
    assert(run(dir, "fontinst " .. tmp), "Could not create input encoding!")
    j = j .. ".enc"
    f = assert(io.open(j, "rb"),"Cannot read " .. j .. "!")
    local content = f:read("*all")
    f:close()
    local new_content = string.gsub(content, "TeXMathItalicEncoding", "EBGaramondTeXMathItalicEncoding")
    new_content = string.gsub(new_content, "oldstyle", "")
    new_content = string.gsub(new_content, "/mu", "/uni03BC")
    new_content = string.gsub(new_content, "/epsilon1", "/epsilon")
    f = assert(io.open(j,"w"))
    f:write((string.gsub(new_content,"\n",fnt.os_newline_cp)))
    f:close()
  end
  -- convert fonts & generate support files
  otf2tfm (otftotfm.mapfile,dir,otftotfm.otfs,otftotfm.encs,otftotfm.opts)
  if fileexists(dir .. "/pdftex.map") then rm(dir,"pdftex.map") end
  -- return home
  assert(lfs.chdir(gohome), "Could not switch to " .. gohome .. "!")
  dir = origdir
  if fnt.nifergwall ~= 0 then return fnt.nifergwall end
  assert(fnt.build_tidy(), "Could not tidy " .. fnt.fntdir .. " -- NOT PROCEEDING TO KEEP!")
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
-- }}}
-------------------------------------------------
textfiles = {"*.md", "*.txt"}
typesetruns = 5
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
	version    = "v1.3",
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
if fileexists(maindir .. "/ffnt-manifest.lua") then
  dofile(maindir .. "/ffnt-manifest.lua")
elseif fileexists(maindir .. "/../nfssext/ffnt-manifest.lua") then
  dofile(maindir .. "/../nfssext/ffnt-manifest.lua")
end
if fileexists(maindir .. "/../nfssext/tag.lua") then
  dofile(maindir .. "/../nfssext/tag.lua")
end
-------------------------------------------------
-- vim: ts=2:sw=2:tw=0:nospell:et:foldmethod=marker:
