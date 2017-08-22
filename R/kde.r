library(mvtnorm)

#' Fit a kernel density estimate
#'
#' description
#' @param x Matrix or vector of samples. For matrices, rows are samples and columns are variables.
#' @param adjust Scalar multiplication of the bandwidth
#' @param bw.fn Function used to calculate the bandwidth. If diagonal = T, bw.fn should accept a vector of 1-dimensional values. If diagonal = F, bw.fn should accept a matrix of samples.
#' @param ... Further arguments are passed to bw.fn
#' @export
#' @examples
#' x <- rmvnorm(50, c(0, 0), rbind(c(1, 0.5), c(0.5, 1)))
#' fit <- fit.kde(x)
#' fit <- fit.kde(x, bw.fn = Hpi, diagonal = F)
fit.kde <- function(x, adjust = 1, bw.fn = bw.SJ, diagonal = T, verbose = F, ...)
{
    n <- nrow(x)
    d <- ncol(x)

    result <- list()
    result$type <- "kde"
    result$dim <- ncol(x)
    result$x <- x

    if (diagonal) {
        factor <- n ^ (-1 / (d + 4))
        bw <- adjust * factor * apply(x, 2, bw.fn, ...)
        result$H <- diag(bw)
    } else {
        result$H <- adjust * bw.fn(x, ...)
    }
    return(structure(result, class = "mdd.density"))
}

#' Fit a transformed kernel density estimate
#'
#' Fits a kernel density estimates after transforming the variables to an unbounded domain.
#' [0,inf] -> log
#' [0,1] -> logit 
#' [a,b] -> scaled logit
#' @param x Matrix or vector of samples. For matrices, rows are samples and columns are variables.
#' @param bounds Dx2 matrix of boundaries which determine the type of transformation to use.
#' @param adjust Scalar multiplication of the bandwidth
#' @param bw.fn Function used to calculate the bandwidth. If diagonal = T, bw.fn should accept a vector of 1-dimensional values. If diagonal = F, bw.fn should accept a matrix of samples.
#' @param ... Further arguments are passed to bw.fn
#' @export
#' @examples
#' x <- exp(rmvnorm(50, c(0, 0), rbind(c(1, 0.5), c(0.5, 1))))
#' fit <- fit.kde(x, rbind(c(0,inf), c(0, inf))
#' fit <- fit.kde(x, rbind(c(0,inf), c(0, inf), bw.fn = Hpi, diagonal = F)
fit.kde.transformed <- function(x, bounds, adjust = 1, bw.fn = bw.SJ, diagonal = T, verbose = F)
{
    result <- list()
    result$type <- "kde.transformed"
    result$transform.bounds <- bounds
    transformed <- mdd.transform_to_unbounded(x, bounds)
    result$kde <- fit.kde(transformed, adjust = adjust, bw.fn = bw.fn, diagonal = diagonal)
    return(structure(result, class = "mdd.density"))
}

.evaluate.kde <- function(fit, x, log = FALSE)
{
    tp <- rep(NA, nrow(x))
    for (i in 1:nrow(x)) {
        p <- dmvnorm(fit$x, x[i,], fit$H)
        if (log) {
            tp[i] <- log(sum(p)) - log(nrow(fit$x))
        } else {
            tp[i] <- sum(p) / nrow(fit$x)
        }
    }
    return(tp)
}