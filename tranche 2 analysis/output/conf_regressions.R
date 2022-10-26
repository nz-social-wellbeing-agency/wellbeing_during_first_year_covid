#
# Automated confidentialisation of regression outputs
# (improved/general version now available under Resources)
# Simon Anastasiadis
# 2022-07-12
#

## setup ------------------------------------------------------------------------------------------

continuous_input_file = "continuous_regression_outputs.txt"
logit_input_file = "logit_regression_output.txt"
output_file = "regression_outputs.txt"
status_file = "RR3_applied.txt"

out_con = file(output_file, "a")
status_con = file(status_file, "a")

## continuous regressions / R regressions ---------------------------------------------------------

in_con = file(continuous_input_file, "r")

KEYWORD_EXISTS = "^\\w* Panel: n = "
KEYWORD_start_n1 = "^\\w* Panel: n = \\d"
KEYWORD_end_n1 = "^\\w* Panel: n = \\d*"
KEYWORD_start_n2 = "^\\w* Panel: n = \\d*. T = [^ ]*, N = \\d"
KEYWORD_end_n2 = "^\\w* Panel: n = \\d*. T = [^ ]*, N = \\d*"

while( TRUE ){
  line = readLines(in_con, n = 1)
  if(length(line) == 0){
    break
  }
  
  if(grepl(KEYWORD_EXISTS, line)){
    
    start_digit_1 = regexec(KEYWORD_start_n1, line)
    start_digit_1 = attributes(start_digit_1[[1]])$match.length
    
    end_digit_1 = regexec(KEYWORD_end_n1, line)
    end_digit_1 = attributes(end_digit_1[[1]])$match.length
    
    start_digit_2 = regexec(KEYWORD_start_n2, line)
    start_digit_2 = attributes(start_digit_2[[1]])$match.length
    
    end_digit_2 = regexec(KEYWORD_end_n2, line)
    end_digit_2 = attributes(end_digit_2[[1]])$match.length
    
    pre = substr(line, 1, start_digit_1 - 1)
    n1 = substr(line, start_digit_1, end_digit_1)
    mid = substr(line, end_digit_1 + 1, start_digit_2 - 1)
    n2 = substr(line, start_digit_2, end_digit_2)
    pst = substr(line, end_digit_2 + 1, nchar(line))
    
    n1 = n1 %>%
      as.numeric() %>%
      randomly_round_vector()
    
    n2 = n2 %>%
      as.numeric() %>%
      randomly_round_vector()
    
    # output RR3 file
    out_line = paste0(pre,n1,mid,n2,pst)
    writeLines(out_line, out_con)
    
    # output report
    writeLines("input line processed:", status_con)
    writeLines(line, status_con)
    writeLines("replaced with RR3 version:", status_con)
    writeLines(out_line, status_con)
    writeLines("------------------------------------", status_con)
    
  } else {
    writeLines(line, out_con)
  }
}

close(in_con)

## logit regressions / Stata regressions ----------------------------------------------------------

in_con = file(logit_input_file, "r")
# in_con = file("test.txt", "r")

KEYWORD1_EXISTS = "^note: [0-9]"
KEYWORD2_EXISTS = "Number of obs\\s*=\\s*"
KEYWORD3_EXISTS = "Number of groups\\s*=\\s*"

KEYWORD1_start1 = "^note: [0-9]"
KEYWORD1_end1 = "^note: [0-9,]*"
KEYWORD1_start2 = "^note: [0-9,]* groups \\([0-9]"
KEYWORD1_end2 = "^note: [0-9,]* groups \\([0-9,]*"

KEYWORD2_start = "^.*Number of obs\\s*=\\s*[0-9]"
KEYWORD2_end = "^.*Number of obs\\s*=\\s*[0-9,]*"
KEYWORD3_start = "^.*Number of groups\\s*=\\s*[0-9]"
KEYWORD3_end = "^.*Number of groups\\s*=\\s*[0-9,]*"

while( TRUE ){
  line = readLines(in_con, n = 1)
  if(length(line) == 0){
    break
  }
  
  if(grepl(KEYWORD1_EXISTS, line)){
    start1_1 = regexec(KEYWORD1_start1, line)
    start1_1 = attributes(start1_1[[1]])$match.length
    
    end1_1 = regexec(KEYWORD1_end1, line)
    end1_1 = attributes(end1_1[[1]])$match.length
    
    start1_2 = regexec(KEYWORD1_start2, line)
    start1_2 = attributes(start1_2[[1]])$match.length
    
    end1_2 = regexec(KEYWORD1_end2, line)
    end1_2 = attributes(end1_2[[1]])$match.length
    
    pre = substr(line, 1, start1_1 - 1)
    n1 = substr(line, start1_1, end1_1)
    mid = substr(line, end1_1 + 1, start1_2 - 1)
    n2 = substr(line, start1_2, end1_2)
    pst = substr(line, end1_2 + 1, nchar(line))
    
    n1 = n1 %>%
      gsub(pattern = ",", replacement = "") %>%
      as.numeric() %>%
      randomly_round_vector()
    
    n2 = n2 %>%
      gsub(pattern = ",", replacement = "") %>%
      as.numeric() %>%
      randomly_round_vector()
    
    # output RR3 file
    out_line = paste0(pre,n1,mid,n2,pst)
    writeLines(out_line, out_con)
    
    # output report
    writeLines("input line processed:", status_con)
    writeLines(line, status_con)
    writeLines("replaced with RR3 version:", status_con)
    writeLines(out_line, status_con)
    writeLines("------------------------------------", status_con)
    
  } else if(grepl(KEYWORD2_EXISTS, line)){
    start2 = regexec(KEYWORD2_start, line)
    start2 = attributes(start2[[1]])$match.length
    
    end2 = regexec(KEYWORD2_end, line)
    end2 = attributes(end2[[1]])$match.length
    
    pre = substr(line, 1, start2 - 1)
    nn = substr(line, start2, end2)
    pst = substr(line, end2 + 1, nchar(line))
    
    nn = nn %>%
      gsub(pattern = ",", replacement = "") %>%
      as.numeric() %>%
      randomly_round_vector()
    
    # output RR3 file
    out_line = paste0(pre,nn,pst)
    writeLines(out_line, out_con)
    
    # output report
    writeLines("input line processed:", status_con)
    writeLines(line, status_con)
    writeLines("replaced with RR3 version:", status_con)
    writeLines(out_line, status_con)
    writeLines("------------------------------------", status_con)
    
  } else if(grepl(KEYWORD3_EXISTS, line)){
    start3 = regexec(KEYWORD3_start, line)
    start3 = attributes(start3[[1]])$match.length
    
    end3 = regexec(KEYWORD3_end, line)
    end3 = attributes(end3[[1]])$match.length
    
    pre = substr(line, 1, start3 - 1)
    nn = substr(line, start3, end3)
    pst = substr(line, end3 + 1, nchar(line))
    
    nn = nn %>%
      gsub(pattern = ",", replacement = "") %>%
      as.numeric() %>%
      randomly_round_vector()
    
    # output RR3 file
    out_line = paste0(pre,nn,pst)
    writeLines(out_line, out_con)
    
    # output report
    writeLines("input line processed:", status_con)
    writeLines(line, status_con)
    writeLines("replaced with RR3 version:", status_con)
    writeLines(out_line, status_con)
    writeLines("------------------------------------", status_con)
    
  } else {
    writeLines(line, out_con)
  }
  
  

}

close(in_con)

## end --------------------------------------------------------------------------------------------

close(out_con)
close(status_con)
