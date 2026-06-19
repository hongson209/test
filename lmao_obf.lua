-- [SON HUB V3.5 // Multi-Part Loader] -- DO NOT EDIT --
-- Requires _G.SH_P[1..4] to be loaded BEFORE this file.
local S,T,B=string,table,bit32 or bit
local PARTS=4
local K={83,48,110,72,52,120,75,51,121,33,50,48,50,54}
local KS=#K

if not _G.SH_P then error("[SonHub] payload parts not loaded") end
local buf={}
for i=1,PARTS do
    if not _G.SH_P[i] then error("[SonHub] missing part "..i) end
    buf[i]=_G.SH_P[i]
end
local A=T.concat(buf)
_G.SH_P=nil

-- base64 decode
local D={}
for i=1,64 do D[S.byte("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",i)]=i-1 end
local function b64(s)
    s=s:gsub("=","")
    local r,n,i={},#s,1
    while i<=n do
        local a=D[S.byte(s,i)] or 0
        local b=D[S.byte(s,i+1)] or 0
        local c=D[S.byte(s,i+2)] or 0
        local d=D[S.byte(s,i+3)] or 0
        r[#r+1]=S.char(a*4+(b-b%16)/16)
        if i+2<=n then r[#r+1]=S.char((b%16)*16+(c-c%4)/4) end
        if i+3<=n then r[#r+1]=S.char((c%4)*64+d) end
        i=i+4
    end
    return T.concat(r)
end
local raw=b64(A)

-- xor decrypt
local out={}
for i=1,#raw do
    local b=S.byte(raw,i)
    local k=K[((i-1)%KS)+1]
    local p=((i-1)*7+13)%256
    out[i]=S.char(B.bxor(B.bxor(b,k),p))
end
local comp=T.concat(out)

-- lzw decode
local cs={}
for i=1,#comp,2 do cs[#cs+1]=S.byte(comp,i)*256+S.byte(comp,i+1) end
local dt={}
for i=0,255 do dt[i]=S.char(i) end
local nc,res=256,{}
local prev=dt[cs[1]]
res[1]=prev
for i=2,#cs do
    local c=cs[i]
    local e
    if dt[c] then e=dt[c]
    elseif c==nc then e=prev..S.sub(prev,1,1)
    else error("LZW@"..i) end
    res[#res+1]=e
    if nc<65536 then dt[nc]=prev..S.sub(e,1,1); nc=nc+1 end
    prev=e
end

local F=T.concat(res)
local fn,err=(loadstring or load)(F)
if not fn then error("[SonHub] decode failed: "..tostring(err)) end
return fn()