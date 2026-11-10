local _detalhes = _G._detalhes

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> constants
local habilidade_dano = _detalhes.habilidade_dano

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> internals
function habilidade_dano:NovaTabela(id, link, token)
	local _newDamageSpell = {
		total = 0, --total damage
		counter = 0, --counter
		id = id, --spellid
		successful_casted = 0, --successful casted times(only for enemies)

		--> normal hits
		n_min = 0,
		n_max = 0,
		n_amt = 0,
		n_dmg = 0,

		--> critical hits
		c_min = 0,
		c_max = 0,
		c_amt = 0,
		c_dmg = 0,

		--> glacing hits
		g_amt = 0,
		g_dmg = 0,

		--> resisted
		r_amt = 0,
		r_dmg = 0,

		--> blocked
		b_amt = 0,
		b_dmg = 0,

		--> obsorved
		a_amt = 0,
		a_dmg = 0,

		targets = {}
	}

	if token == "SPELL_PERIODIC_DAMAGE" then
		_detalhes:SpellIsDot(id)
	end

	return _newDamageSpell
end

function habilidade_dano:AddMiss(serial, nome, flags, who_nome, missType)
	self.counter = self.counter + 1
	self[missType] = (self[missType] or 0) + 1

	self.targets[nome] = self.targets[nome] or 0
end

function habilidade_dano:Add(serial, nome, flag, amount, who_nome, resisted, blocked, absorbed, critical, glacing, token, isoffhand)
	-- print(serial, nome, flag, amount, who_nome, resisted, blocked, absorbed, critical, glacing, token, isoffhand)
	self.total = self.total + amount

	self.targets[nome] = (self.targets[nome] or 0) + amount

	self.counter = self.counter + 1

	if resisted and resisted > 0 then
		self.r_dmg = self.r_dmg + amount --> tabela.total � o total de dano
		self.r_amt = self.r_amt + 1 --> tabela.total � o total de dano
	end

	if blocked and blocked > 0 then
		self.b_dmg = self.b_dmg + amount --> amount � o total de dano
		self.b_amt = self.b_amt + 1 --> amount � o total de dano
	end

	if absorbed and absorbed > 0 then
		self.a_dmg = self.a_dmg + amount --> amount � o total de dano
		self.a_amt = self.a_amt + 1 --> amount � o total de dano
	end

	if glacing then
		self.g_dmg = self.g_dmg + amount --> amount � o total de dano
		self.g_amt = self.g_amt + 1 --> amount � o total de dano
	elseif critical then
		self.c_dmg = self.c_dmg + amount --> amount � o total de dano
		self.c_amt = self.c_amt + 1 --> amount � o total de dano

		if amount > self.c_max then
			self.c_max = amount
		end

		if self.c_min > amount or self.c_min == 0 then
			self.c_min = amount
		end
	else
		self.n_dmg = self.n_dmg + amount
		self.n_amt = self.n_amt + 1

		if amount > self.n_max then
			self.n_max = amount
		end

		if self.n_min > amount or self.n_min == 0 then
			self.n_min = amount
		end
	end
	-- print("last")
end
