.logit <- function(x) { log(x / (1 - x)) }
.dlogit <- function(x) { 1 / (x - x * x) }
.logistic <- function(x) { 1 / (1 + exp(-x)) }
.logit_scale <- function(x, a, b) { log((a - x) / (x - b)) }
.dlogit_scale <- function(x, a, b) {(b - a) / ((a - x) * (x - b)) }
.logistic_scale <- function(x, a, b) { ex <- exp(x); (a + b * ex) / (ex + 1) }

#' Transform to an unbounded domain
#'
#' description
#' @param x Matrix or vector of samples. For matrices, rows are samples and columns are variables.
#' @param bounds Dx2 matrix specifying the lower and upper bound for each variable.
#' @export
mvd.transform_to_unbounded <- function(x, bounds) {
    transformed <- matrix(NA, nrow = nrow(x), ncol = ncol(x))
    for (i in 1:ncol(x)) {
        if (bounds[i, 1] >= bounds[i, 2]) {
            stop("Upper bound must be strictly higher than lower bound")
        }

        if (bounds[i, 1] == 0 && bounds[i, 2] == 1) {
            # [0,1] -> logit
            transformed[, i] <- .logit(x[, i])
        } else if (bounds[i, 1] == 0 && bounds[i, 2] == Inf) {
            # [0,inf] -> log
            transformed[, i] <- log(x[, i])
        } else if (bounds[i, 1] == -Inf && bounds[i, 2] == 0) {
            # [0,inf] -> log
            transformed[, i] <- log(-x[, i])
        } else if (bounds[i, 1] == -Inf && bounds[i, 2] == Inf) {
            # [-inf,inf] -> no transform
            transformed[, i] <- x[, i]
        } else {
            # [a,b] -> scaled logit
            transformed[, i] <- .logit_scale(x[, i], bounds[i, 1], bounds[i, 2])
        }
    }
    return(transformed)
}

#' Reverse transform from an unbounded domain
#'
#' description
#' @param transformed_x Matrix or vector of transformed samples. For matrices, rows are samples and columns are variables.
#' @param bounds Dx2 matrix specifying the lower and upper bound for each variable.
#' @export
mvd.transform_from_unbounded <- function(transformed_x, bounds) {
    x <- matrix(NA, nrow = nrow(x), ncol = ncol(x))
    for (i in 1:ncol(x)) {
        if (bounds[i, 1] == 0 && bounds[i, 2] == 1) {
            # [0,1] -> logit -> inverse = logistic
            x[, i] <- .logistic(transformed_x[, i])
        } else if (bounds[i, 1] == 0 && bounds[i, 2] == Inf) {
            # [0,inf] -> log -> inverse = exp
            x[, i] <- exp(transformed_x[, i])
        } else if (bounds[i, 1] == -Inf && bounds[i, 2] == 0) {
            # [0,inf] -> log -> inverse = exp
            x[, i] <- -exp(transformed_x[, i])
        } else if (bounds[i, 1] == -Inf && bounds[i, 2] == Inf) {
            # [-inf,inf] -> no transform
            x[, i] <- transformed_x[, i]
        } else {
            # [a,b] -> scaled logit -> inverse = scaled logistic
            x[, i] <- .logistic_scale(transformed_x[, i], bounds[i, 1], bounds[i, 2])
        }
    }
    return(x)
}

#' Probability density correction for variable transformation
#' @param x Matrix or vector of samples. For matrices, rows are samples and columns are variables.
#' @param bounds Dx2 matrix specifying the lower and upper bound for each variable.
#' @param p Probability densities to correct
#' @param log Specifies whether p is in log scale
#' @export
mvd.correct_p_for_transformation <- function(x, bounds, p, log = T) {
    if (log) {
        for (i in 1:ncol(x)) {
            if (bounds[i, 1] == 0 && bounds[i, 2] == 1) {
                # [0,1] -> logit -> derivative = dlogit
                p <- p + log(.dlogit(x[, i]))
            } else if (bounds[i, 1] == 0 && bounds[i, 2] == Inf) {
                # [0,inf] -> log -> derivative = 1/log
                p <- p - log(x[, i])
            } else if (bounds[i, 1] == -Inf && bounds[i, 2] == 0) {
                # [0,inf] -> log -> derivative = 1/log
                p <- p - log(x[, i])
            } else if (bounds[i, 1] == -Inf && bounds[i, 2] == Inf) {
                # [-inf,inf] -> no transform
            } else {
                # [a,b] -> scaled logit -> derivative = dlogit_scale
                p <- p + log(.dlogit_scale(x[, i], bounds[i, 1], bounds[i, 2]))
            }
        }
    } else {
        for (i in 1:ncol(x)) {
            if (bounds[i, 1] == 0 && bounds[i, 2] == 1) {
                # [0,1] -> logit -> derivative = dlogit
                p <- p * .dlogit(x[, i])
            } else if (bounds[i, 1] == 0 && bounds[i, 2] == Inf) {
                # [0,inf] ->log(x) -> 1/x
                p <- p / x[, i]
            } else if (bounds[i, 1] == -Inf && bounds[i, 2] == 0) {
                # [0,inf] ->log(x) -> 1/x
                p <- p / x[, i]
            } else if (bounds[i, 1] == -Inf && bounds[i, 2] == Inf) {
                # [-inf,inf] -> no transform
            } else {
                # [a,b] -> scaled logit -> derivative = dlogit_scale
                p <- p * .dlogit_scale(x[, i], bounds[i, 1], bounds[i, 2])
            }
        }
    }
    return(p)
}

.mvd.transform_name <- function(bounds, i) {
    if (bounds[i, 1] == 0 && bounds[i, 2] == 1) {
        return("logit")
    } else if (bounds[i, 1] == 0 && bounds[i, 2] == Inf) {
        return("log")
    } else if (bounds[i, 1] == -Inf && bounds[i, 2] == 0) {
        return("negative log")
    } else if (bounds[i, 1] == -Inf && bounds[i, 2] == Inf) {
        return("no transform")
    } else {
        return("scaled logit")
    }
}
