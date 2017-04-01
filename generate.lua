--[[
  a HTML/CSS generator, designed to make updating the site easier
--]]
os.execute("cd "..(... or ""))
local err,https=pcall(require,"https")
local arg=...
if not err then
  print("you need to install luasec")
  print("install using luarocks")
  print("or https://github.com/brunoos/luasec/wiki")
  print(https)
  os.exit()
end

local res,err=xpcall(function()
  local file=assert(io.open((arg or "").."repos.cfg","r"))
  local repodat=load("return "..file:read("*a"), nil, nil, {})()
  file:close()
  local repos={}
  for name,data in pairs(repodat) do
    local out={
      name,(data.repo or "none")
    }
    for k,v in pairs(data.programs or {}) do
      table.insert(out,{
        k,v.repo,v.desc
      })
    end
    table.insert(repos,out)
  end

  table.sort(repos,function(a,b)
    return a[1]:lower()<b[1]:lower()
  end)
  -- crappy parsing
  local function parse(yaml)
    local out={}
    for line in yaml:gmatch("[^\r\n]+") do
      if not line:match("^#") then
        local t,m=line:match("^(%s*)(.*)")
        t=t:gsub("  ","\t")
        if #t==0 and #m>0 then
          table.insert(out,{m:match("(.+):")})
        elseif #t==1 then
          if m:match(":$") then
            table.insert(out[#out],{m:match("(.+):")})
          else
            table.insert(out[#out],m)
          end
        elseif #t==2 then
          local t=out[#out]
          table.insert(t[#t],m)
        end
      end
    end
    return out
  end

  local function get(url)
    local res,code=https.request(url)
    if code==200 then
      return res
    end
  end

  for l1=1,#repos do
    local prog=repos[l1]
    if prog[2]~="none" then
      local data=get("https://raw.githubusercontent.com/"..prog[2].."/master/programs.cfg")
      if data then
        data,err=load("return "..data, nil, nil, {})
        if not data then
          print("Error in "..prog[2])
          error(err)
        end
        data=data()
        for name,dat in pairs(data) do
          if not dat.hidden then
            if dat.repo then
              table.insert(prog,{
                name,
                prog[2].."/"..dat.repo,
                dat.description,
              })
            else
              table.insert(prog,{
                name,
                nil,
                dat.description,
              })
            end
          end
        end
      else
        print("WARNING: "..prog[2].." doesnt have a programs.cfg")
        local data=get("https://raw.githubusercontent.com/"..prog[2].."/master/programs.yaml")
        if data then
          repos[l1]=parse(data)
          table.insert(repos[l1],1,prog[2])
          table.insert(repos[l1],1,prog[1])
        else
          print("WARNING: "..prog[2].." doesnt have a programs.yaml and cant be listed")
        end
      end
    end
  end

  local url_override_because_vexatos={
    ["immibis-compress"]="/tree/master/immibis-compress",
    ipack="/blob/master/immibis-compress/ipack.lua",
    dnsd="/blob/master/dns-server.lua",
  }
  local html=[[
<html>
	<head>
		<title>OpenPrograms</title>
		<meta charset="utf-8">
		<link rel="stylesheet" type="text/css" href="style.css">
		<link rel="icon" type="image/ico" href="favicon.ico">
		<script src="scripts/search.js"></script>
	</head>
	<body>
		<center><a href="https://github.com/OpenPrograms"><img src="logo.png"></a></center>
		<div class="bvc" align="right"><input type="text" id="searchbox" placeholder="Search for something here" size="30" maxlength="60" oninput="search();"/><input type="button" id="btnSearch" value="Search" onclick="search();" /></div>
]]
  print("\ngenerating page\n")
  for _,dat in pairs(repos) do
    local name=dat[1]
    print("repo "..tostring(name))
    if dat[2]~="none" then
      dat[2]="https://github.com/"..dat[2]
      html=html.."\t\t<div align=\"left\" name=\"content\" class=\"bvc\"><div class=\"bevel tl tr\"></div><div class=\"content\"><a href=\""..dat[2].."\"><div class=\"title\">"..name.."</div></a>"
    else
      dat[2]="https://github.com/"
      html=html.."\t\t<div align=\"left\" name=\"content\" class=\"bvc\"><div class=\"bevel tl tr\"></div><div class=\"content\"><div class=\"title\">"..name.."</div>"
    end
    html=html.."\n\t\t<table>\n"
    for ind=3,#dat do
      local pdat=dat[ind]
      if type(pdat)=="table" then
        print("\tprogram "..tostring(pdat[1]))
        local url=pdat[2] or url_override_because_vexatos[pdat[1]]
        if url then
          if url:sub(1,1)=="/" then
            url=dat[2]..url
          else
            url="https://github.com/"..url
          end
          html=html.."\t\t\t<tr><td><a href=\""..url.."\">"..pdat[1].."</a></td><td>: "..pdat[3].."</td></tr>\n"
        else
          print("\t\tWARNING: "..pdat[1].." doesnt have a url!")
          html=html.."\t\t\t<tr><td><a style=\"color:#505050\">"..pdat[1].."</a></td><td>: "..pdat[3].."</td></tr>\n"
        end
      else
        html=html.."\t\t\t"..pdat.."\n"
      end
    end
    html=html.."\t\t</table></div><div class=\"bevel bl br\"></div></div>\n"
  end
  local date=os.date("!*t")
  local gen=date.month.."/"..date.day.." at "..date.hour..":"..("0"):rep(2-#tostring(date.min))..date.min
  html=html..[[
  </body>
</html>
  ]]
  local file=assert(io.open((arg or "").."index.html","w"))
  file:write(html)
  file:close()
end,debug.traceback)
if not res then
  print(err)
end
