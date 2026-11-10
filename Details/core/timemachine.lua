local _detalhes = _G._detalhes

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> local pointers
local _ipairs = ipairs --lua local
local _math_floor = math.floor --lua local
local _pairs = pairs --lua local
local _table_insert = table.insert --lua local
local _table_wipe = table.wipe --lua local
local _time = time --lua local


local timeMachine = _detalhes.timeMachine --details local

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> constants
local _tempo = _time()

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> core
timeMachine.ligada = false

local calc_hold = function(self, idle_time)
	for tipo, tabela in _pairs(self.tabelas) do
		for nome, jogador in _ipairs(tabela) do
			if jogador then
				if jogador.last_event + idle_time > _tempo then
					if jogador.on_hold then
						jogador:HoldOn(false)
					end
				elseif not jogador.on_hold then
					jogador:HoldOn(true)
				end
			end
		end
	end
end

function timeMachine:Core()
	_tempo = _time()
	_detalhes._tempo = _tempo
	_detalhes:UpdateGears()

	return calc_hold(self, (_detalhes.is_in_battleground or _detalhes.is_in_arena) and 3 or 10)
end

function timeMachine:Ligar()
	self.atualizador = self:ScheduleRepeatingTimer("Core", 1)
	self.ligada = true
	self.tabelas = {{}, {}} --> 1 dano 2 cura

	local danos = _detalhes.tabela_vigente[1]._ActorTable
	for _, jogador in _ipairs(danos) do
		if jogador.dps_started then
			jogador:RegistrarNaTimeMachine()
		end
	end
end

function timeMachine:Reiniciar()
	_table_wipe(self.tabelas[1])
	_table_wipe(self.tabelas[2])
end

function _detalhes:DesregistrarNaTimeMachine()
	if not timeMachine.ligada then
		return
	end

	local timeMachineContainer = timeMachine.tabelas[self.tipo]
	local actorTimeMachineID = self.timeMachine

	if timeMachineContainer[actorTimeMachineID] == self then
		self:TerminarTempo()
		self.timeMachine = nil
		timeMachineContainer[actorTimeMachineID] = false
	end
end

function _detalhes:RegistrarNaTimeMachine()
	if not timeMachine.ligada then
		return
	end

	local esta_tabela = timeMachine.tabelas[self.tipo]
	_table_insert(esta_tabela, self)
	self.timeMachine = #esta_tabela
end

function _detalhes:ManutencaoTimeMachine()
	for tipo, tabela in _ipairs(timeMachine.tabelas) do
		local t = {}
		for index, jogador in _ipairs(tabela) do
			if jogador then
				t[#t + 1] = jogador
				jogador.timeMachine = #t
			end
		end

		timeMachine.tabelas[tipo] = t
	end
end

function _detalhes:Tempo()
	local min_time = self.pvp and 3 or 10
	if self.end_time then --> o tempo do jogador esta trancado
		local t = self.end_time - self.start_time
		if t < min_time then
			t = min_time
		end

		return t
	elseif self.on_hold then --> o tempo esta em pausa
		local t = self.delay - self.start_time
		if t < min_time then
			t = min_time
		end

		return t
	else
		if self.start_time == 0 then
			return min_time
		end

		local t = _tempo - self.start_time
		if t < min_time then
			if _detalhes.in_combat then
				local combat_time = _detalhes.tabela_vigente:GetCombatTime()
				if combat_time < min_time then
					return combat_time
				end
			end

			t = min_time
		end

		return t
	end
end

function _detalhes:TerminarTempo()
	if self.end_time then
		return
	end

	if self.on_hold then
		self:HoldOn(false)
	end

	self.end_time = _tempo
end

--> diz se o dps deste jogador esta em pausa
function _detalhes:HoldOn(pausa)
	if pausa == nil then
		return self.on_hold --retorna se o dps esta aberto ou fechado para este jogador
	elseif pausa then --> true - colocar como inativo
		self.delay = _math_floor(self.last_event) --_tempo - 10
		if self.delay < self.start_time then
			self.delay = self.start_time
		end

		self.on_hold = true
	else --> false - retornar a atividade
		local diff = _tempo - self.delay - 1
		if diff > 0 then
			self.start_time = self.start_time + diff
		end

		self.on_hold = false
	end
end