# Ouvre un projet de terrain engendre par sommieR comme le ferait QGIS (voir
# qgis/ouvrir_projet.py) ; saute le test sans PyQGIS.
ouvrir_dans_qgis <- function(qgs) {
  script <- testthat::test_path("qgis", "ouvrir_projet.py")
  python <- Sys.which("python3")
  skip_if(!nzchar(python), "python3 absent.")
  sonde <- suppressWarnings(system2(python, c("-c", shQuote("import qgis.core")),
                                    stdout = FALSE, stderr = FALSE))
  skip_if(sonde != 0L, "PyQGIS absent.")
  sortie <- suppressWarnings(system2(
    python, c(shQuote(script), shQuote(qgs)), stdout = TRUE, stderr = FALSE,
    env = "QT_QPA_PLATFORM=offscreen"
  ))
  ligne <- grep("^JSON:", sortie, value = TRUE)
  expect_length(ligne, 1L)
  jsonlite::fromJSON(sub("^JSON:", "", ligne), simplifyVector = FALSE)
}
