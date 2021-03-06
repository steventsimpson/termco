#' Model Accuracy
#'
#' Check a model's tagging/categorizing accuracy against known expert coded
#' outcomes.
#'
#' @param x The model classification \code{\link[base]{list}}/\code{\link[base]{vector}}
#' (typically the results of \code{classify}).
#' @param known The known expert coded \code{\link[base]{list}}/\code{\link[base]{vector}} of outcomes.
#' @return Returns a list of five elements:
#' \item{exact.in}{A numeric vector between 0-1 (0 no match; 1 perfect match) comparing \code{x} to \code{known} for exact matching.}
#' \item{any.in}{A numeric vector between 0-1 (0 no match; 1 perfect match) comparing \code{x} to \code{known} for non-location specific matching (\code{\%in\%} is used).  This ignores the differences in length between \code{x} and \code{known}.}
#' \item{logical.in}{A logical version of \code{exact} with \code{TRUE} being equal to 1 and all else being \code{FALSE}.  This can be used to locate perfect and/or non matches.}
#' \item{exact}{The proportion of the vector of tags in \code{x} matching \code{known} exactly.}
#' \item{ordered}{The proportion of the elements of tags in \code{x} matching \code{known} exactly (order matters).}
#' \item{adjusted}{An adjusted mean score of \code{ordered} and \code{unordered}.}
#' \item{unordered}{The proportion of the elements of tags in \code{x} matching \code{known} exactly regardless of order.}
#' @keywords accuracy model fit
#' @export
#' @examples
#' known <- list(1:3, 3, NA, 4:5, 2:4, 5, integer(0))
#' tagged <- list(1:3, 3, 4, 5:4, c(2, 4:3), 5, integer(0))
#' accuracy(tagged, known)
#'
#' ## Examples
#' library(dplyr)
#' data(presidential_debates_2012)
#'
#' discoure_markers <- list(
#'     response_cries = c("\\boh", "\\bah", "\\baha", "\\bouch", "yuk"),
#'     back_channels = c("uh[- ]huh", "uhuh", "yeah"),
#'     summons = "hey",
#'     justification = "because"
#' )
#'
#'
#' ## Only Single Tag Allowed Per Text Element
#' mod1 <- presidential_debates_2012 %>%
#'     with(., term_count(dialogue, TRUE, discoure_markers)) %>%
#'     classify()
#'
#' fake_known <- mod1
#' set.seed(1)
#' fake_known[sample(1:length(fake_known), 300)] <- "random noise"
#'
#' accuracy(mod1, fake_known)
#'
#' ## Multiple Tags Allowed
#' mod2 <- presidential_debates_2012 %>%
#'     with(., term_count(dialogue, TRUE, discoure_markers)) %>%
#'     classify(n = 2)
#'
#' fake_known2 <- mod2
#' set.seed(30)
#' fake_known2[sample(1:length(fake_known2), 500)] <- c("random noise", "back_channels")
#'
#' accuracy(mod2, fake_known2)
accuracy <- function(x, known){

    stopifnot(length(x) == length(known))

    if (!is.list(x)) x <- as.list(x)
    if (!is.list(known)) known <- as.list(known)
    x <- lapply(x, function(a) sapply(a, function(b) {b[is.na(b)] <- "No_Code_Given"; b}))
    known <- lapply(known, function(a) sapply(a, function(b) {b[is.na(b)] <- "No_Code_Given"; b}))

    out <- acc_test(x, known)
    logic <- out[["exact"]] == 1
    propcor <- sum(logic, na.rm = TRUE)/length(logic)
    ordered_out <- sum(out[["exact"]],na.rm = TRUE)/length(out[["exact"]])
    unordered_out <- sum(out[["any.in"]],na.rm = TRUE)/length(out[["any.in"]])
    score <- mean(c(ordered_out, unordered_out), na.rm = TRUE)
    out <- list(exact.in = unname(out[[1]]), any.in = unname(out[[2]]),
        logical.in = logic, exact = propcor, ordered = ordered_out,
        unordered =unordered_out, adjusted = score)
    class(out) <- "accuracy"
    out

}

#' Prints an accuracy Object
#'
#' Prints an accuracy object
#'
#' @param x The accuracy object.
#' @param \ldots ignored
#' @method print accuracy
#' @export
print.accuracy <- function(x, ...){
    cat(sprintf("N:         %s\n", length(x[["logical.in"]])))
    cat(sprintf("Exact:     %s%%\n", digit_format(100*x[["exact"]], 1)))
    cat(sprintf("Ordered:   %s%%\n", digit_format(100*x[["ordered"]], 1)))
    cat(sprintf("Adjusted:  %s%%\n", digit_format(100*x[["adjusted"]], 1)))
    cat(sprintf("Unordered: %s%%\n", digit_format(100*x[["unordered"]], 1)))
}

acc_test <- function(x, y){

    out <- unlist(Map(function(a, b){dists(a, b)}, x, y))
    out2 <- unlist(Map(function(a, b){dists2(a, b)}, x, y))
    #1-(((1 - (1/(1 + exp(out)))) * 2) - 1)
    list(exact = out, any.in = out2)
}



dists <- function(x, y) {

    #nas <- unlist(lapply(list(x, y), function(z){
    #    any(sapply(z, is.na))
    #}))

    #if(isTRUE(all(nas))) return(1)
    #if(isTRUE(any(nas))) return(0)
#if (any(is.na(y))) browser()
    suppressWarnings(sum(x == y)/(.5*(length(x) + length(y))))
}

dists2 <- function(x, y) {

    #nas <- unlist(lapply(list(x, y), function(z){
    #    any(sapply(z, is.na))
    #}))

    #if(isTRUE(all(nas))) return(1)
    #if(isTRUE(any(nas))) return(0)

    sum(x %in% y)/(.5*(length(x) + length(y)))
}












