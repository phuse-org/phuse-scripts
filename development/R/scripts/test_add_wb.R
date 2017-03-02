## Create a new workbook
wb <- createWorkbook("test01")
## Add 3 worksheets
addWorksheet(wb, "Sheet 1")
addWorksheet(wb, "Sheet 2", gridLines = FALSE)
addWorksheet(wb, "Sheet 3", tabColour = "red")
addWorksheet(wb, "Sheet 4", gridLines = FALSE, tabColour = "#4F81BD")
## Headers and Footers
addWorksheet(wb, "Sheet 5",
             header = c("ODD HEAD LEFT", "ODD HEAD CENTER", "ODD HEAD RIGHT"),
             footer = c("ODD FOOT RIGHT", "ODD FOOT CENTER", "ODD FOOT RIGHT"),
             evenHeader = c("EVEN HEAD LEFT", "EVEN HEAD CENTER", "EVEN HEAD RIGHT"),
             evenFooter = c("EVEN FOOT RIGHT", "EVEN FOOT CENTER", "EVEN FOOT RIGHT"),
             firstHeader = c("TOP", "OF FIRST", "PAGE"),
             firstFooter = c("BOTTOM", "OF FIRST", "PAGE"))
addWorksheet(wb, "Sheet 6",
             header = c("&[Date]", "ALL HEAD CENTER 2", "&[Page] / &[Pages]"),
             footer = c("&[Path]&[File]", NA, "&[Tab]"),
             firstHeader = c(NA, "Center Header of First Page", NA),
             firstFooter = c(NA, "Center Footer of First Page", NA))
addWorksheet(wb, "Sheet 7",
             header = c("ALL HEAD LEFT 2", "ALL HEAD CENTER 2", "ALL HEAD RIGHT 2"),
             footer = c("ALL FOOT RIGHT 2", "ALL FOOT CENTER 2", "ALL FOOT RIGHT 2"))
addWorksheet(wb, "Sheet 8",
             firstHeader = c("FIRST ONLY L", NA, "FIRST ONLY R"),
             firstFooter = c("FIRST ONLY L", NA, "FIRST ONLY R"))
## Need data on worksheet to see all headers and footers
writeData(wb, sheet = 5, 1:400)
writeData(wb, sheet = 6, 1:400)
writeData(wb, sheet = 7, 1:400)
writeData(wb, sheet = 8, 1:400)
## Save workbook
saveWorkbook(wb, "test01.xlsx", overwrite = TRUE)
