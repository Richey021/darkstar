-----------------------------------------
-- Spell: Cure V
-- Restores target's HP.
-- Shamelessly stolen from http://members.shaw.ca/pizza_steve/cure/Cure_Calculator.html
-----------------------------------------

require("scripts/globals/settings");
require("scripts/globals/status");
require("scripts/globals/magic");

-----------------------------------------
-- OnSpellCast
-----------------------------------------

function onSpellCast(caster,target,spell)

	--Pull base stats from caster.
	MND = caster:getStat(MOD_MND);
	VIT = target:getStat(MOD_VIT);
	Healing = caster:getSkillLevel(HEALING_MAGIC_SKILL);

	power = ((3 * MND) + (VIT) + (3 * math.floor(Healing / 5)));
	--printf("MIND: %u",MND);
	--printf("VIT: %u",VIT);
	--printf("POWER: %u",power);

	-- Rate and Constant are based on which soft caps have been overcome by the caster.
	rate = 0.6666;
	constant = 330;
	if(power > 560) then
		rate = 2.8333;
		constant = 591.2;
	elseif(power > 320) then
		rate = 1;
		constant = 410;
	end

	--Amount to cure the target with.
	cure = (math.floor(power / 2)) / (rate) + constant;
	--printf("CURE: %u",cure);

	--Adjust bonus for bonus.
	bonus = AffinityBonus(caster,spell);

	--Check for cure potency equipment.
	potency = curePotency(caster);

	day = 1;--spellDayWeatherBonus(caster, spell, false);
	--print("Total day/weather bonus:",day);

	--Final amount to heal the target with.
	final = cure * bonus * day * (1 + potency) * CURE_POWER;

	--Raise the amount above the minimum hard cap.
	if(final < 450) then
		final = 450;
	end;

	if(caster:getStatusEffect(EFFECT_AFFLATUS_SOLACE) ~= nil) and (target:getStatusEffect(EFFECT_STONESKIN) == nil) then
	  Afflatus_Stoneskin = math.floor(final / 4);
	  if(Afflatus_Stoneskin > 300) then
		  Afflatus_Stoneskin = 300;
	  end;
	  --printf("Additional effect on target: Stoneskin");
	  target:addStatusEffect(EFFECT_STONESKIN,Afflatus_Stoneskin,0,25);
	end;

	--Check to see if the target doesn't need that much healing.
	maxhp = target:getMaxHP();
	hp = target:getHP();
	diff = (maxhp - hp);
	mobfinal = final;
	if(final > diff) then
		final = diff;
	end

	--Truncate decimal amounts.
	final = math.floor(final);
	
	-- Do it!
	if(target:getRank() ~= nil) then
		if(caster:getStatusEffect(EFFECT_DIVINE_SEAL) ~= nil) then
			final = final * 2;
		end
		target:addHP(final);
	else
		if(target:isUndead()) then
			spell:setMsg(2);
			if(mobfinal < 0) then
				mobfinal = mobfinal * -1;
			end
			target:delHP(mobfinal);
			final = mobfinal;
		else
			final = 0;
		end
	end
	
	caster:updateEnmityFromCure(target,65535); --65535 is the special code for "cure v enmity generation"
	return final;
	
end;