function Think()
{
	if (self==player.GetActiveWeapon()) 
	{
		self.SetReloadsSingly(true)
	}
	else self.SetReloadsSingly(false);
	return 0
}
// чувак который имплементировал эту ебучую вепон фактори вообще нихуя не тестировал то что высрал - дамаг пушек залочен на 3 единицы,
// параметр reloads_singly нихуя не работает. ещё какая-то залупа со звуками перезарядки есть ну и хуй с ней.