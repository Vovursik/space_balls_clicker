extends Node

func format_number(number: int, decimal: int = 1) -> String:
	var suffixes = ["", "k", "m", "b", "t", "qd", "qt"]
	
	if number < 1000:
		return str(number)
	
	var value = float(number)
	var index = 0
	
	while value >= 1000 and index < suffixes.size() - 1:
		value /= 1000.0
		index += 1
	
	var mult = pow(10.0, decimal)
	var rounded = round(value * mult) / mult
	
	if rounded == floor(rounded):
		return str(int(rounded)) + suffixes[index]
	
	# Самая быстрая форматирование
	var int_part = int(rounded)
	var frac_part = int(round(rounded * mult)) % int(mult)
	
	if frac_part == 0:
		return str(int_part) + suffixes[index]
	
	# Убираем нули в дробной части
	while frac_part % 10 == 0 and frac_part > 0:
		frac_part /= 10
	
	return str(int_part) + "." + str(frac_part) + suffixes[index]
