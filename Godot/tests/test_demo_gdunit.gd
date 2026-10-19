extends GdUnitTestSuite
## Essai de GdUnit4 : un test de pure logique, sans fenêtre de jeu.


func test_addition() -> void:
	assert_int(2 + 2).is_equal(4)


func test_espece_lue_sans_jeu() -> void:
	var species: Resource = load("res://data/species/trex_magma.tres")
	assert_object(species).is_not_null()
