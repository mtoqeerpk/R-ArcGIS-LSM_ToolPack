#olan ve olmayan alanlarin secili oldugu Shape dosyalarini az olan alana gore 
#####################################################################################################  
### T�B�TAK 3501 - KAR�YER GEL��T�RME PROGRAMI TARAFINDAN DESTEKLENM��T�R
### Proje No: 118Y090
### Proje Ad�: "Heyelan Duyarl�l�k Haritalar� �retimi i�in R Programlama Dili Yard�m�yla ARCGIS Ara Y�zlerinin Geli�tirilmesi"
### Proje Y�r�t�c�s�: Emrehan Kutlu� �AH�N
### Proje Ara�t�rma Ekibi: Do�.Dr. �smail ��lkesen
### Proje Dan��ma Ekibi: Prof.Dr. Aykut AKG�N ; Prof.Dr. Arif �a�da� AYDINO�LU
### Proje Asistan� Ekibi: ��heda Semih A�MALI
#####################################################################################################  
###########   KOD DETAYLARI VE EK B�LG�LER             ##############
#####################################################################################################
#########################
### Ara� Ad�: 
### Ara� Amac�: 
### Ara� ��eri�i: 
### Yararlan�lan K�t�phane isim ve Web sayfalar�: 
##################################################################################################### 
# alanlarin buyukluge degil sayisina gore %70 train %30 test
#verisi olarak raster veriye cevirip kaydeder

tool_exec <- function(in_params, out_params)
{
  #####################################################################################################  
  ### Check/Load Required Packages  ####  K�t�phanelerin Kontrol Edilmesi/Y�klenmesi
  #####################################################################################################   
  library(arcgisbinding)
  arc.check_product()
  arc.progress_label("K�t�phaneler Y�kleniyor...")
  arc.progress_pos(0)
  
  
  if (!requireNamespace("rgdal", quietly = TRUE))
    install.packages("rgdal")
  if (!requireNamespace("raster", quietly = TRUE))
    install.packages("raster")
  if (!requireNamespace("sp", quietly = TRUE))
    install.packages("sp")
  if (!requireNamespace("rgeos", quietly = TRUE))
    install.packages("rgeos")
  if (!requireNamespace("svDialogs", quietly = TRUE))
    install.packages("svDialogs")
  
  require(sp)
  require(rgdal)
  require(raster)
  require(rgeos)
  require(svDialogs)
  #yazilan fonksiyonlarin uzantilari
  source("C:/Users/Public/kullanilanFonksiyonlar.R")

  ##################################################################################################### 
  ### Define input/output parameters #### Girdi/��kt� Parametrelerinin Tan�mlanmas�
  ##################################################################################################### 
  #dosya uzantilari
  olanPath <- in_params[[1]]
  olmayanPath <- in_params[[2]]
  percentvalue <- as.integer(in_params[[3]])
  resolation <-  as.integer(in_params[[4]])
  #Uretilecek olan Raster verinin kaydedilecegi yer ve adi
  kayitPath <- out_params[[1]]
  kayitPath2 <- out_params[[2]]
  #heyelan Olan ve olmayan alanlar� i�eren polygon datas�n� okumak ve raster train datas�na d�n��t�rmek.
  
  ##################################################################################################### 
  ### Load Landslide and NonLandSlide Shape Data  ####  Heyelan Olan ve Olmayan Alan  Verilerinin Y�klenmesi
  #####################################################################################################
  arc.progress_label("Veri Y�kleniyor...")
  arc.progress_pos(20)
  #-------- Heyelan olan ve olmayan alanlarin shape dosyasindan okunmasi ve train, test olarak ayrilmasi -------------
  olanShp <- arc.open(olanPath)
  olanShp <- arc.data2sp(arc.select(olanShp))
  
  olmayanShp <- arc.open(olmayanPath)
  olmayanShp <- arc.data2sp(arc.select(olmayanShp))

  #CRS kodlarinin kontrol edilmesi;
  #Uyu�mazl�k veya Bo� de�er olmas� durumunda uyari verir.
  #Uyar� sonucunda kullan�c� devam etmesini isteyebilir
  result <- "sonuc"
  crsCodes <- c(proj4string(olanShp), proj4string(olmayanShp))
  result <- CrsCheck(crsCodes)
  if(result == "cancel") return(out_params)
  
  
  #Extentler aras�nda kesi�im noktas�n�n kontrol edilmesi i�lemi
  #e�er kesi�im noktalar� yoksa bunlar ya parkl� koordinat sistemindedirler yada
  #farkl� yerleri g�stermektedir. Bu �ekilde i�lem yap�lamayaca��ndan
  #uyar� ekran� ��kart�lm��t�r
  cevap <- "cevap"
  extents <- c(extent(olanShp),extent(olmayanShp))
  cevap <-extentCheck(extents)
  if(cevap == "no") return(out_params)
  
  #heyelan olan olanlarin 1 olamyan alanlarin 0 olarak atanmasi birlestirme yapildiginda gerekli olacak veri ayirmasi icin
  
  olanShp$heyelanTur <- 1
  olmayanShp$heyelanTur <- 0


  ##################################################################################################### 
  ### Train Test Split  ####  E�itim Test Verisinin Ayr�lmas�
  #####################################################################################################
  arc.progress_label("Verilen Y�zdeye G�re Ayr�m Yap�l�yor...")
  arc.progress_pos(40)
  #train test veri sayisinin belirlenmesi
  olantrain <- as.integer(nrow(olanShp)*percentvalue/100)
  olmayantrain <- as.integer(nrow(olmayanShp)* percentvalue/100)

  #heyelan olan alanlarin polygonlarin train ve test kadarinin se�ilmesi
  olantrainsample <- sample(1:nrow(olanShp), olantrain)
  
  #heyelan olmayan alanlarin polygonlarin train ve test kadarinin se�ilmesi
  olmayantrainsample <- sample(1:nrow(olmayanShp), olmayantrain)
  arc.progress_label("Heyelan Olan Alanlar E�itim ve Test Olarak Ayr�l�yor...")
  arc.progress_pos(45)
  #heyelan olan alanlarin polygonlarin train ve test olarak ayrilmasi ayrilmasi
  olantrainpolygon <- olanShp[olantrainsample,]
  olantestpolygon <- olanShp[-(olantrainsample),]
  arc.progress_label("Heyelan Olmayan Alanlar E�itim ve Test Olarak Ayr�l�yor...")
  arc.progress_pos(50)
  #heyelan olmayan alanlarin polygonlarin train ve test olarak ayrilmasi ayrilmasi
  olmayantrainpolygon <- olmayanShp[olmayantrainsample,]
  olmayantestpolygon <- olmayanShp[-(olmayantrainsample),]
  ##################################################################################################### 
  ### Create Train, Test Shape Data  ####  E�itim, Test Verisinin Olu�turulmas
  #####################################################################################################
  arc.progress_label("E�itim Ve Test Verisi olu�turuluyor...")
  arc.progress_pos(60)
  #heyelan olan ve olamayan train ve test verilerinin birlestirilmesi
  trainShp <- bind(olantrainpolygon, olmayantrainpolygon)
  testShp <- bind(olantestpolygon, olmayantestpolygon)
  rm(olantestpolygon,olmayantestpolygon,olmayantrainpolygon,olantrainpolygon)
  
  ##################################################################################################### 
  ### Train, Test Shape Data Turn to Raster Data  ####  E�itim, Test Verisinin Raster'a D�n��t�r�lmesi
  #####################################################################################################
  arc.progress_label("Poligon Verisi Raster Veriye �evriliyor...")
  arc.progress_pos(80)
  
  trainRaster <- ShapetoRaster(trainShp,resolation,"heyelanTur")
  testRaster <- ShapetoRaster(testShp,resolation,"heyelanTur")
  crs(trainRaster) <- crs(testRaster) <- crs(olanShp)
  ##################################################################################################### 
  ### Write Out Train Test Data  ###  E�itim Test Verilerinin Yazd�r�lmas�
  #####################################################################################################
  arc.progress_label("E�itim ve Test Verisi Yazd�r�l�yor...")
  arc.write(data = trainRaster, path = if(grepl("\\.tif$", kayitPath)| grepl("\\.img$", kayitPath)) kayitPath
            else paste0(normalizePath(dirname(kayitPath)),"\\", sub('\\..*$', '', basename(kayitPath)),".tif") 
            ,overwrite=TRUE)
  arc.write(data = testRaster, path = if(grepl("\\.tif$", kayitPath2)| grepl("\\.img$", kayitPath2)) kayitPath2
            else paste0(normalizePath(dirname(kayitPath2)),"\\", sub('\\..*$', '', basename(kayitPath2)),".tif")
            ,overwrite=TRUE)
  arc.progress_pos(100)
return(out_params)
}