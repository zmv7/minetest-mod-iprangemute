local s = minetest.get_mod_storage()

local to_x = function(pat)
	return (pat and pat:gsub("%%d%+","X") or "error")
end

minetest.register_on_joinplayer(function(player)
	local name = player and player:get_player_name()
	local pinfo = name and minetest.get_player_information(name)
	local ip = pinfo and pinfo.address
	if ip then
		local stor_table = s:to_table()
		local list = stor_table and stor_table.fields
		if not list then return end
		for pat,descr in pairs(list) do
			if ip:match(pat) then
				local privs = minetest.get_player_privs(name)
				if privs then
					privs.shout = nil
					minetest.set_player_privs(name, privs)
					minetest.after(0.1, minetest.chat_send_player, name, "You have been muted because your IP belongs to blacklisted IP range: "..to_x(pat)..(descr and descr ~= "dummy" and " ("..descr..")" or ""))
					minetest.log("action",name.." ["..ip.."] is mutted by IPRangeMute")
				end
			end
		end
	end
end)

minetest.register_chatcommand("ipmute",{
  description = "IP range mute",
  privs = {server=true},
  params = "[<add> | <rm> <IP pattern> [description]] | <ls>",
  func = function(name,param)
	local action, ip_descr = param:match("^(%S+) (.+)$")
	if not (action and ip_descr) then
		action = param
		if action == "ls" then
			local stor_table = s:to_table()
			local list = stor_table and stor_table.fields
			if not list then return end
			local out = {}
			for pat,descr in pairs(list) do
				table.insert(out, to_x(pat)..(descr and descr ~= "dummy" and "("..descr..")" or ""))
			end
			table.sort(out)
			return true, "List of patterns: "..table.concat(out,", ")
		end
		return false, "Invalid params"
	end
	local ip, descr = ip_descr:match("^(%S+) (.+)$")
	if not (ip and descr) then
		ip = ip_descr
		descr = "dummy"
	end
	local segs = ip:split(".")
	local pattern = {"%d+","%d+","%d+","%d+"}
	for i,seg in ipairs(segs) do
		if seg:match("%D+") then
			seg = "%d+"
		end
		pattern[i] = seg
	end
	local pat = table.concat(pattern,".")
	if action == "add" then
		s:set_string(pat,descr)
		return true, "Added pattern: "..to_x(pat)
	end
	if action == "rm" then
		s:set_string(pat,"")
		return true, "Removed pattern: "..to_x(pat)
	end
end})
