#' Generate parameter estimate plot with 95 percent CI's from a GERGM object.
#'
#' @param GERGM_Object The object returned by the estimation procedure using the
#' GERGM function.
#' @return A parameter estimate plot.
#' @export
Estimate_Plot <- function(GERGM_Object){
  #define colors
  UMASS_BLUE <- rgb(51,51,153,255,maxColorValue = 255)
  UMASS_RED <- rgb(153,0,51,255,maxColorValue = 255)
  Model <- Variable <- Coefficient <- SE <- NULL
  modelFrame <- data.frame(Variable = colnames(GERGM_Object@theta.coef) ,
                           Coefficient = GERGM_Object@theta.coef[,1],
                           SE = GERGM_Object@theta.coef[,2],
                           Model = "Theta Estimates"
  )
  data <- data.frame(modelFrame)

  #now add in lambda estimates
  if(length(GERGM_Object@lambda.coef) > 1){
    temp1 <- as.numeric(GERGM_Object@lambda.coef[1,])
    temp1 <- temp1[1:(length(temp1)-1)]
    temp2 <- as.numeric(GERGM_Object@lambda.coef[2,])
    temp2 <- temp2[1:(length(temp2)-1)]
    modelFrame2 <- data.frame(Variable = dimnames(GERGM_Object@data_transformation)[[3]] ,
                              Coefficient = temp1,
                              SE = temp2,
                              Model = "Lambda Estimates"
    )
    data2 <- data.frame(modelFrame2)
    data <- rbind(data,data2)
  }


  # Plot
  if(length(GERGM_Object@lambda.coef[,1]) > 0){
    zp1 <- ggplot2::ggplot(data, ggplot2::aes(colour = Model)) +
      ggplot2::scale_color_manual(values = c(UMASS_BLUE,UMASS_RED))
  }else{
    zp1 <- ggplot2::ggplot(data, ggplot2::aes(colour = Model)) +
      ggplot2::scale_color_manual(values = UMASS_BLUE)
  }
  zp1 <- zp1 + ggplot2::geom_hline(yintercept = 0, colour = gray(1/2), lty = 2)
  zp1 <- zp1 + ggplot2::geom_linerange( ggplot2::aes(x = Variable,
                  ymin = Coefficient - SE*(-qnorm((1-0.9)/2)),
                  ymax = Coefficient + SE*(-qnorm((1-0.9)/2))),
                  lwd = 1,
                  position = ggplot2::position_dodge(width = 1/2))
  zp1 <- zp1 + ggplot2::geom_pointrange(ggplot2::aes(x = Variable,
                  y = Coefficient,
                  ymin = Coefficient - SE*(-qnorm((1-0.95)/2)),
                  ymax = Coefficient + SE*(-qnorm((1-0.95)/2))),
                  lwd = 1/2,
                  position = ggplot2::position_dodge(width = 1/2),
                  shape = 21, fill = "WHITE")
  zp1 <- zp1  + ggplot2::theme_bw() +
    ggplot2::coord_flip() +
    ggplot2::theme(legend.position="none")
  print(zp1)
}
