# use this to add significance stars to p-values in tables produced by pixiedust
# from https://gist.github.com/nutterb/4a827cfe2403900d72153451c493ccc6


#' @name pvalString
#' @export pvalString
#' 
#' @title Format P-values for Reports
#' @description Convert numeric p-values to character strings according to
#' pre-defined formatting parameters.  Additional formats may be added
#' for required or desired reporting standards.
#' 
#' @param p a numeric vector of p-values.
#' @param format A character string indicating the desired format for 
#'   the p-values.  See Details for full descriptions.
#' @param digits For \code{"exact"} and \code{"scientific"}; indicates the 
#'   number of digits to precede scientific notation.
#' @param stars \code{logical(1)}, should stars be appended to p-values to 
#'   denote significance level.
#' @param stars_break Numeric vector of values between 0 and 1. This vector
#'   is passed to \code{\link{cut}} to determine the how many \code{stars_mark}
#'   characters to append to the p-value.
#' @param stars_mark \code{character(1)}. Designates the character to append
#'   to a p-value when \code{stars = TRUE}. No marks are added when the 
#'   p-value is larger than \code{max(stars_break)}, and one character is 
#'   added to each progressively decreasing category thereafter (ie \code{*},
#'   \code{**}, and \code{***}).
#' @param ... Additional arguments to be passed to \code{format}
#' 
#' @details When \code{format = "default"}, p-values are formatted:
#' \enumerate{
#'   \item \emph{p > 0.99}: "> 0.99"
#'   \item \emph{0.99 > p > 0.10}: Rounded to two digits
#'   \item \emph{0.10 > p > 0.001}: Rounded to three digits
#'   \item \emph{0.001 > p}: "< 0.001"
#'  }
#'  
#'  When \code{format = "exact"}, the exact p-value is printed with the 
#'  number of significant digits equal to \code{digits}.  P-values smaller
#'  that 1*(10^-\code{digits}) are printed in scientific notation.
#'  
#'  When \code{format = "scientific"}, all values are printed in scientific
#'  notation with \code{digits} digits printed before the \code{e}.
#'  
#'  @author Benjamin Nutter
#'  @examples
#'  p <- c(1, .999, .905, .505, .205, .125, .09531,
#'         .05493, .04532, .011234, .00834, .00261, .0003431, .000000342)
#'  pvalString(p, format="default")
#'  pvalString(p, format="exact", digits=3)
#'  pvalString(p, format="exact", digits=2)
#'  pvalString(p, format="scientific", digits=3)
#'  pvalString(p, format="scientific", digits=4)
#'  
#'  pvalString(p, format="default", stars = TRUE)
#'  pvalString(p, format="exact", digits=4, stars = TRUE)
#'  pvalString(p, format="exact", digits=2, stars = TRUE)
#'  pvalString(p, format="scientific", digits=3, stars = TRUE)
#'  pvalString(p, format="scientific", digits=4, stars = TRUE)
#'  
#'  pvalString(p, stars = TRUE, stars_break = c(0.10, 0.05), stars_mark = "!")
#'  
#'  

pvalString_demo <- function (p, 
                        format = c("default", "exact", "scientific"), 
                        digits = 3, 
                        stars = FALSE,
                        stars_break = c(0.05, 0.01, 0.001),
                        stars_mark = "*",
          ...) 
{
  coll <- checkmate::makeAssertCollection()
  
  format <- checkmate::matchArg(x = format,
                                choices = c("default", "exact", "scientific"),
                                add = coll)

  valid_p <- checkmate::test_numeric(x = p,
                                     lower = 0,
                                     upper = 1) 
  if (!valid_p)
  {
    notProb <- which(p < 0 | p > 1)
    coll$push(sprintf("Element(s) %s are not valid probabilities",
                      paste(notProb, collapse = ", ")))
  }
  
  checkmate::assert_logical(x = stars,
                            len = 1,
                            add = coll)
  
  if (stars)
  {
    checkmate::assert_numeric(x = stars_break,
                              lower = 0,
                              upper = 1,
                              add = coll)
    
    checkmate::assert_character(x = stars_mark,
                                len = 1,
                                add = coll)
  }

  checkmate::reportAssertions(coll)
  
  ps <- switch(
    format,
    "default" = ifelse(test = p > 0.99, 
                       yes = "> 0.99", 
                       no = ifelse(test = p > 0.1, 
                                   yes = sprintf("%1.2f", p), 
                                   no = ifelse(test = p > 0.001, 
                                               yes = sprintf("%1.3f", p), 
                                               no = "< 0.001"))),
    "exact" = ifelse(test = p < 1 * (10^-digits), 
                     yes = format(p, 
                                  scientific = TRUE, 
                                  digits = digits), 
                     no = format(round(p, digits), 
                                 digits = digits)),
    "scientific" = format(p, scientific = TRUE, digits = digits)
  )

  if (stars)
  {
    star_append <- cut(x = p, 
                       breaks = c(0, stars_break, 1))
    
    star_append <- 
      vapply(nlevels(star_append) - as.numeric(star_append),
             FUN = function(x, stars_mark) 
               {
                 rep(stars_mark, x) %>%
                 paste(collapse = "") 
               },
             FUN.VALUE = character(1),
             stars_mark)
    
    star_append <- stringr::str_pad(string = star_append,
                                    width = max(nchar(star_append)),
                                    side = "right",
                                    pad = " ")
    
    ps <- paste0(ps, star_append)
  }
  
  return(ps)
}

