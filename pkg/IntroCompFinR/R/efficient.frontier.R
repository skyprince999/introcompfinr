efficient.frontier <-
function(er, cov.mat, nport=20, alpha.min=-0.5, alpha.max=1.5, shorts=TRUE)
{
  # Compute efficient frontier with no short-sales constraints
  #
  # inputs:
  # er			  N x 1 vector of expected returns
  # cov.mat	  N x N return covariance matrix
  # nport		  scalar, number of efficient portfolios to compute
  # shorts          logical, allow shorts is TRUE
  #
  # output is a Markowitz object with the following elements
  # call		  captures function call
  # er			  nport x 1 vector of expected returns on efficient porfolios
  # sd			  nport x 1 vector of std deviations on efficient portfolios
  # weights 	nport x N matrix of weights on efficient portfolios 
  call <- match.call()

  #
  # check for valid inputs
  #
  asset.names <- names(er)
  er <- as.vector(er)
  N <- length(er)
  cov.mat <- as.matrix(cov.mat)
  if(N != nrow(cov.mat))
    stop("invalid inputs")
  if(any(diag(chol(cov.mat)) <= 0))
    stop("Covariance matrix not positive definite")

  #
  # create portfolio names
  #
  port.names <- rep("port",nport)
  ns <- seq(1,nport)
  port.names <- paste(port.names,ns)

  #
  # compute global minimum variance portfolio
  #
  cov.mat.inv <- solve(cov.mat)
  one.vec <- rep(1, N)
  port.gmin <- globalMin.portfolio(er, cov.mat, shorts)
  w.gmin <- port.gmin$weights

  if(shorts==TRUE){
    # compute efficient frontier as convex combinations of two efficient portfolios
    # 1st efficient port: global min var portfolio
    # 2nd efficient port: min var port with ER = max of ER for all assets
    er.max <- max(er)
    port.max <- efficient.portfolio(er,cov.mat,er.max)
    w.max <- port.max$weights    
    a <- seq(from=alpha.min,to=alpha.max,length=nport)			# convex combinations
    we.mat <- a %o% w.gmin + (1-a) %o% w.max	# rows are efficient portfolios
    er.e <- we.mat %*% er							# expected returns of efficient portfolios
    er.e <- as.vector(er.e)
  } else if(shorts==FALSE){
    we.mat <- matrix(0, nrow=nport, ncol=N)
    we.mat[1,] <- w.gmin
    we.mat[nport, which.max(er)] <- 1
    er.e <- as.vector(seq(from=port.gmin$er, to=max(er), length=nport))
    for(i in 2:(nport-1)) 
      we.mat[i,] <- efficient.portfolio(er, cov.mat, er.e[i], shorts)$weights
  } else {
    stop("shorts needs to be logical. For no-shorts, shorts=FALSE.")
  }
  
  names(er.e) <- port.names
  cov.e <- we.mat %*% cov.mat %*% t(we.mat) # cov mat of efficient portfolios
  sd.e <- sqrt(diag(cov.e))					# std devs of efficient portfolios
  sd.e <- as.vector(sd.e)
  names(sd.e) <- port.names
  dimnames(we.mat) <- list(port.names,asset.names)

  # 
  # summarize results
  #
  ans <- list("call" = call,
	      "er" = er.e,
	      "sd" = sd.e,
	      "weights" = we.mat)
  class(ans) <- "Markowitz"
  ans
}
