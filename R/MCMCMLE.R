MCMCMLE <- function(num.draws,
                    mc.num.iterations,
                    tolerance,
                    thin = 1,
                    MCMC.burnin,
                    theta = NULL,
                    alpha = NULL,
                    directed ,
                    method ,
                    shape.parameter ,
                    together ,
                    seed2 ,
                    gain.factor,
					          possible.stats,
					          GERGM_Object,
					          force_x_theta_updates) {

  statistics <- GERGM_Object@stats_to_use
  alphas <- GERGM_Object@weights
  cat("Estimating Initial Values for Theta via MPLE... \n")
  GERGM_Object <- store_console_output(GERGM_Object,"Estimating Initial Values for Theta via MPLE... \n")

  if(GERGM_Object@is_correlation_network){
    theta.init <- mple.corr(GERGM_Object@network, GERGM_Object@bounded.network,
                            statistics = GERGM_Object@stats_to_use,
                            directed = directed)
  }else{
    theta.init <- mple(GERGM_Object@bounded.network,
                       statistics = GERGM_Object@stats_to_use,
                       directed = directed)
  }

  cat("\nMPLE Thetas: ", theta.init$par, "\n")
  GERGM_Object <- store_console_output(GERGM_Object,paste("\nMPLE Thetas: ", theta.init$par, "\n"))
  num.nodes <- GERGM_Object@num_nodes
  triples <- t(combn(1:num.nodes, 3))
  pairs <- t(combn(1:num.nodes, 2))
  if(GERGM_Object@is_correlation_network){
    # initialize the network with the observed network
    initial_network <- GERGM_Object@network
    # calculate the statistics of the original network
    init.statistics <- h2(GERGM_Object@network,
                          triples = triples,
                          statistics = rep(1, length(possible.stats)),
                          alphas = alphas, together = together)
    obs.stats <- h2(GERGM_Object@network,
                    triples = triples,
                    statistics = GERGM_Object@stats_to_use,
                    alphas = alphas,
                    together = together)
  }else{
    # initialize the network with the observed network
    initial_network <- GERGM_Object@bounded.network
    # calculate the statistics of the original network
    init.statistics <- h2(GERGM_Object@bounded.network,
                          triples = triples,
                          statistics = rep(1, length(possible.stats)),
                          alphas = alphas, together = together)
    obs.stats <- h2(GERGM_Object@bounded.network,
                    triples = triples,
                    statistics = GERGM_Object@stats_to_use,
                    alphas = alphas,
                    together = together)
  }


  #cat("Observed Values of Selected Statistics:", "\n", obs.stats, "\n")
  ####################################################################
  ##JW: Added 3/29/15. This scales the initial estimates for the MPLE theta specification
  ## This is according to the initialization the Fisher Scoring method for optimization
  alps <- alphas[which(statistics == 1)]
  GERGM_Object@reduced_weights <- alps
  GERGM_Object@theta.par <- theta.init$par
  GERGM_Object@MCMC_output
  GERGM_Object <- Simulate_GERGM(GERGM_Object,
                         nsim = ceiling(20/thin),
                         method = method,
                         shape.parameter = shape.parameter,
                         together = together,
                         thin = thin,
                         MCMC.burnin = MCMC.burnin,
                         seed1 = seed2,
                         possible.stats = possible.stats)

  hsn <- GERGM_Object@MCMC_output$Statistics[,which(GERGM_Object@stats_to_use == 1)]

  #Calculate covariance estimate (to scale initial guess theta.init)
  z.bar <- colSums(hsn) / 20
  #cat("z.bar", "\n", z.bar, "\n")
  Cov.est <- 0
  for(i in 1:dim(hsn)[1]){
    Cov.est <- matrix(as.numeric(hsn[i,]), ncol = 1) %*% t(matrix(as.numeric(hsn[i,]), ncol = 1)) + Cov.est
  }
  Cov.est <- (Cov.est / 20) - z.bar%*%t(z.bar)
  #cat("Cov.est", "\n", Cov.est)
  D.inv <- solve(Cov.est)
  #calculate
  theta <- list()
  theta$par <- theta.init$par - gain.factor * D.inv %*% (z.bar - obs.stats)
  cat("Adjusted Initial Thetas After Fisher Update:",theta$par, "\n\n")
  GERGM_Object <- store_console_output(GERGM_Object,paste("Adjusted Initial Thetas After Fisher Update:",theta$par, "\n\n"))
  ##########################################################################
  ## Simulate new networks
  for (i in 1:mc.num.iterations) {
    GERGM_Object@theta.par <- as.numeric(theta$par)
    GERGM_Object <- Simulate_GERGM(GERGM_Object,
                           nsim = num.draws,
                           method = method,
                           shape.parameter = shape.parameter,
                           together = together,
                           thin = thin,
                           MCMC.burnin = MCMC.burnin,
                           seed1 = seed2,
                           possible.stats = possible.stats)


    #just use what gets returned
#     if(GERGM_Object@is_correlation_network){
#       #calculate the statistics on the correlation space
#       temp <- GERGM_Object@MCMC_output$Networks
#       num.nodes <- dim(temp)[1]
#       for(i in 1:dim(temp)[3]){
#         temp.net <- bounded.to.correlations((temp[, , i] + t(temp[, , i]))/2)
#         if(i == 1){
#           hsn <- h2(temp.net, triples = triples,
#                     statistics = rep(1, 6),
#                     alphas = alphas,
#                     together = together)
#         }
#         if(i > 1){
#           hsn <- rbind(hsn, h2(temp.net, triples = triples,
#                                statistics = rep(1, 6),
#                                alphas = alphas,
#                                together = together))
#         }
#       }
#       hsn.tot <- hsn
#       hsn <- hsn[, which(statistics == 1)]
#     }else{
    # }
    hsn <- GERGM_Object@MCMC_output$Statistics[,which(statistics == 1)]
    hsn.tot <- GERGM_Object@MCMC_output$Statistics

    stats.data <- data.frame(Observed = init.statistics,
                             Simulated = colMeans(hsn.tot))
    rownames(stats.data) <- possible.stats
    print(stats.data)
    GERGM_Object <- store_console_output(GERGM_Object,toString(stats.data))
    cat("\nOptimizing Theta Estimates... \n")
    GERGM_Object <- store_console_output(GERGM_Object,"\nOptimizing Theta Estimates... \n")
    theta.new <- optim(par = theta$par,
                       log.l,
                       alpha = GERGM_Object@reduced_weights,
                       hsnet = hsn,
                       ltheta = as.numeric(theta$par),
                       together = together,
                       possible.stats= possible.stats,
                       GERGM_Object = GERGM_Object,
                       method = "BFGS",
                       hessian = T,
                       control = list(fnscale = -1, trace = 5))
    cat("\n", "Theta Estimates: ", paste0(theta.new$par,collapse = " "), "\n",sep = "")
    GERGM_Object <- store_console_output(GERGM_Object,paste("\n", "Theta Estimates: ", paste0(theta.new$par,collapse = " "), "\n",sep = ""))
    theta.std.errors <- 1 / sqrt(abs(diag(theta.new$hessian)))
    # Calculate the p-value based on a z-test of differences
    # The tolerance is the alpha at which differences are significant
    p.value <- rep(0,length(as.numeric(theta$par)))
    count <- rep(0, length(as.numeric(theta$par)))
    for(j in 1:length(theta$par)){
      #two sided z test
      p.value[j] <- 2*pnorm(-abs((as.numeric(theta.new$par)[j] - as.numeric(theta$par)[j])/theta.std.errors[j]))
      #abs(theta.new$par[i] - theta$par[i]) > bounds[i]
      #if we reject any of the tests then convergence has not been reached!
      if(p.value[j] < tolerance){count[j] = 1}
    }
    cat("\np.values for two-sided z-test of difference between current and updated theta estimates:\n\n")
    GERGM_Object <- store_console_output(GERGM_Object,"\np.values for two-sided z-test of difference between current and updated theta estimates:\n\n")
    cat(round(p.value,3), "\n \n")
    GERGM_Object <- store_console_output(GERGM_Object,paste(p.value, "\n \n"))

    if(max(abs(theta.new$par)) > 10000000){
      message("Parameter estimates appear to have become degenerate, returning previous thetas. Model output should not be trusted. Try specifying a larger number of simulations or a different parameterization.")
      GERGM_Object <- store_console_output(GERGM_Object,"Parameter estimates appear to have become degenerate, returning previous thetas. Model output should not be trusted. Try specifying a larger number of simulations or a different parameterization.")
      return(list(theta.new,GERGM_Object))
    }

    if (sum(count) == 0){
      #conditional to check and see if we are requiring a second update
      if(i >= force_x_theta_updates){
        message("Parameter estimates have converged")
        GERGM_Object <- store_console_output(GERGM_Object,"Parameter estimates have converged")
        GERGM_Object@theta_estimation_converged <- TRUE
        return(list(theta.new,GERGM_Object))
      }else{
        message(paste("Forcing",force_x_theta_updates,"iterations of theta updates..."),sep = " ")
        GERGM_Object <- store_console_output(GERGM_Object,paste("Forcing",force_x_theta_updates,"iterations of theta updates..."))
      }
    }
    #cat("\n", "Theta Estimates", theta.new$par, "\n",sep = "")
    theta <- theta.new
    GERGM_Object@theta.par <- as.numeric(theta$par)
  }
  return(list(theta.new,GERGM_Object))
}
