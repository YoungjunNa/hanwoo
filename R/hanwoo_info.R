#' hanwoo_info
#'
#' This function scrap the information of Hanwoo from data.go.kr. Please get your API key and request for applicate at data.go.kr.
#' @param cattle Number of cattle you get the inform.
#' @param key_encoding Encoded API key from data.go.kr.
#' @param key_decoding Decoded API key from data.go.kr.
#' @param time_check Check the response time of the server.
#' @keywords Hanwoo
#' @export
#' @import XML
#' @import tibble
#' @importFrom lubridate ymd
#' @import dplyr
#' @import readr
#' @examples
#' hanwoo_info(cattle = "002083191603", key_encoding, key_decoding)
#' hanwoo_info(cattle = "002115280512", key_encoding, key_decoding)

hanwoo_info <- function(cattle, key_encoding, key_decoding, time_check = FALSE) {
  # time check point ----
  if(time_check == TRUE) {
    start_time <- Sys.time()
  }

  # result ----
  result <- list()

  # check the nchar of cattle number ----
  if (nchar(cattle) == 10) {
    cattle <- paste0("00", as.character(cattle))
  }

  if (nchar(cattle) == 9) {
    cattle <- paste0("000", as.character(cattle))
  }

  # check the api error msg ----
  basic_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/animalTrace/traceNoSearch?ServiceKey=", key_encoding, "&traceNo=", cattle, "&optionNo=", 1) %>%
    xmlParse() %>%
    xmlRoot()

  if(xmlToDataFrame(basic_info)$resultCode[1] == 99) {
    return(xmlToDataFrame(basic_info)$resultMsg[1])
  }

  ## 이력정보 ----
  basic_info <- basic_info %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE) %>%
    as_tibble() %>%
    mutate(
      birthYmd = ymd(birthYmd)
    )

  farm_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/animalTrace/traceNoSearch?ServiceKey=", key_encoding, "&traceNo=", cattle, "&optionNo=", 2) %>%
    xmlParse() %>%
    xmlRoot() %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE) %>%
    as_tibble() %>%
    mutate(
      cattleNo = cattle,
      regYmd = ymd(regYmd)
    ) %>%
    select(cattleNo, everything())

  butchery_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/animalTrace/traceNoSearch?ServiceKey=", key_encoding, "&traceNo=", cattle, "&optionNo=", 3) %>%
    xmlParse() %>%
    xmlRoot() %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE) %>%
    as_tibble() %>%
    mutate(butcheryYmd = ymd(butcheryYmd))

  process_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/animalTrace/traceNoSearch?ServiceKey=", key_encoding, "&traceNo=", cattle, "&optionNo=", 4) %>%
    xmlParse() %>%
    xmlRoot() %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE) %>%
    as_tibble()

  vaccine_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/animalTrace/traceNoSearch?ServiceKey=", key_encoding, "&traceNo=", cattle, "&optionNo=", 5) %>%
    xmlParse() %>%
    xmlRoot() %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE) %>%
    as_tibble() %>%
    mutate(injectionYmd = ymd(injectionYmd))

  inspect_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/animalTrace/traceNoSearch?ServiceKey=", key_encoding, "&traceNo=", cattle, "&optionNo=", 6) %>%
    xmlParse() %>%
    xmlRoot() %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE) %>%
    as_tibble()

  brucella_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/animalTrace/traceNoSearch?ServiceKey=", key_encoding, "&traceNo=", cattle, "&optionNo=", 7) %>%
    xmlParse() %>%
    xmlRoot() %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE) %>%
    as_tibble()

  if("inspectDt" %in% colnames(brucella_info)) {
    brucella_info <- brucella_info %>% mutate(inspectDt = ymd(inspectDt))
  }


  lot_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/animalTrace/traceNoSearch?ServiceKey=", key_encoding, "&traceNo=", cattle, "&optionNo=", 8) %>%
    xmlParse() %>%
    xmlRoot() %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE) %>%
    as_tibble()

  seller_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/animalTrace/traceNoSearch?ServiceKey=", key_encoding, "&traceNo=", cattle, "&optionNo=", 9) %>%
    xmlParse() %>%
    xmlRoot() %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE) %>%
    as_tibble()

  # assign the traceability results into list ----
  result$basic_info <- basic_info
  result$farm_info <- farm_info
  result$butchery_info <- butchery_info
  result$process_info <- process_info
  result$vaccine_info <- vaccine_info
  result$inspect_info <- inspect_info
  result$brucella_info <- brucella_info
  result$lot_info <- lot_info
  result$seller_info <- seller_info


  ## 확인서발급정보 ----
  get_issueNo <- paste0("http://data.ekape.or.kr/openapi-data/service/user/grade/confirm/issueNo?animalNo=", cattle, "&ServiceKey=", key_encoding) %>%
    xmlParse() %>%
    xmlRoot() %>%
    getNodeSet("//item") %>%
    xmlToDataFrame(stringsAsFactors = FALSE)

  if (is.null(get_issueNo[1, 1]) == FALSE) {
    get_issueNo <- get_issueNo %>% as_tibble()

    get_issueNo$abattDate <- lubridate::ymd(get_issueNo$abattDate)
    get_issueNo$issueDate <- lubridate::ymd(get_issueNo$issueDate)
    get_issueNo$abattCode <- gsub(" ", "", as.character(get_issueNo$abattCode))

    result$get_issueNo <- get_issueNo
  }

    ## 품질정보 ----
    ## First, we check the error msg ----
    quality_info <- paste0("http://data.ekape.or.kr/openapi-data/service/user/grade/confirm/cattle?issueNo=", get_issueNo$issueNo[1], "&issueDate=", get_issueNo$issueDate[1], "&ServiceKey=", key_decoding) %>%
      xmlParse() %>%
      xmlRoot()

    if(xmlToDataFrame(quality_info)$resultCode[1] == 99) {

      quality_info <- xmlToDataFrame(quality_info)$resultMsg[1]

    } else {

      quality_info <- quality_info %>%
        getNodeSet("//item") %>%
        xmlToDataFrame(stringsAsFactors = FALSE) %>%
        as_tibble() %>%
        mutate(
          qgrade = factor(qgrade, levels = c("D", "3", "2", "1", "1+", "1++")),
          issueDate = ymd(issueDate)
        )


      if("costAmt" %in% names(quality_info) == TRUE) {

        quality_info <- quality_info %>%
          select(
            cattleNo, abattDate, judgeSexNm, birthmonth, qgrade, wgrade,
            costAmt, weight, rea, backfat, insfat, windex,
            tissue, yuksak, fatsak, growth, everything()
          ) %>%
          mutate(
            abattDate = lubridate::ymd(abattDate),
            birthmonth = as.numeric(birthmonth),
            costAmt = as.integer(costAmt),
            weight = as.integer(weight),
            rea = as.integer(rea),
            backfat = as.integer(backfat),
            insfat = as.integer(insfat),
            windex = as.numeric(windex),
            tissue = as.integer(tissue),
            yuksak = as.integer(yuksak),
            fatsak = as.integer(fatsak),
            growth = as.integer(growth)
          )

      } else {

        quality_info <- quality_info %>%
          select(
            cattleNo, abattDate, judgeSexNm, birthmonth, qgrade, wgrade,
            weight, rea, backfat, insfat, windex,
            tissue, yuksak, fatsak, growth, everything()
          ) %>%
          mutate(
            abattDate = lubridate::ymd(abattDate),
            birthmonth = as.numeric(birthmonth),
            costAmt = NA,
            weight = as.integer(weight),
            rea = as.integer(rea),
            backfat = as.integer(backfat),
            insfat = as.integer(insfat),
            windex = as.numeric(windex),
            tissue = as.integer(tissue),
            yuksak = as.integer(yuksak),
            fatsak = as.integer(fatsak),
            growth = as.integer(growth)
          )

      }

    }

  # assign the beef quality results into list ----
  result$quality_info <- quality_info


  # time check ----
  if(time_check == TRUE) {
    time_check <- paste0("Server Respond Time: ", Sys.time() - start_time)
    print(time_check)
  }

  ## return ----
  return(
    tryCatch(
      result,
      error = function(e) NULL
    )
  )
}
