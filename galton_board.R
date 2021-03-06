#almost all the code borrowed from 
#https://github.com/coolbutuseless/chipmunkcore
library(chipmunkcore)
library(ggplot2)
set.seed(1)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Initialize a simulation space
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cm <- Chipmunk$new(time_step = 0.005)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Add funnel segments
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gap <- 2
cm$add_segment( -70, 130, -gap, 91)
cm$add_segment(  70, 130,  gap, 91)
cm$add_segment(-gap, 91, -gap,  90)
cm$add_segment( gap, 91,  gap,  90)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Add pins
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (i in 1:15) {
  y <- 90 - i * 3
  if (i %% 2 == 1) {
    xs <- seq(0, 40, 2)
  } else {
    xs <- seq(1, 40, 2)
  }
  xs <- 1.0 * sort(unique(c(xs, -xs)))
  
  w <- 0.05
  xstart <- xs - w
  xend   <- xs + w
  
  for (xi in seq_along(xs)) {
    cm$add_segment(xstart[xi], y,  xend[xi],  y)
  }
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Add slots 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
floor <- 0
width <- 60
for (x in seq(-width, width, 3)) {
  cm$add_segment(x, floor,  x,  40)
}

cm$add_segment(-width, floor, width, floor)
cm$add_segment(-width, floor-0.2, width, floor-0.2)



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Fetch all the segments. Use for plotting
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
segments_df <- cm$get_segments()

ggplot() +
  geom_segment(data = segments_df, aes(x = x1, y = y1, xend = x2, yend = y2)) +
  coord_fixed() +
  theme_void() +
  theme(legend.position = 'none')


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Add some bodies. Currently only circular bodies supported
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (i in 1:500) {
  cm$add_body(
    x        = runif(1,  -20,  20),
    y        = runif(1,  105, 120),
    radius   = 0.7,
    friction = 0.01
  )
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clear out the target directory for all the frames
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
unlink(list.files("tmp/figures/png", "*.png", full.names = TRUE))


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# (1) advance the simulation (2) plot the bodies. (3) Repeat.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
x0 <- seq(-60,60,len=100)
for (i in 1:1000) {
  
  if (i  %% 10 == 0) message(i)
  
  cm$advance(5)
  
  bodies <- cm$get_bodies()
  
  p <- ggplot(bodies) +
    geom_point(aes(x, y), size = 1.6) +
    geom_segment(data = segments_df, aes(x = x1, y = y1, xend = x2, yend = y2)) +
    coord_fixed() +
    theme_void() +
    theme(legend.position = 'none') + geom_line(data=data.frame(x0),inherit.aes = F,aes(x=x0,y=1000*exp(-x0^2/(2*10^2))/sqrt(2*pi*10^2)),col="darkred",alpha=0.8,lwd=1) + 
    NULL
  
  
  outfile <- sprintf("tmp/%04i.png", i)
  ggsave(outfile, p, width = 7, height = 7)
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ffmpeg - create mp4 from PNG files
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
system("ffmpeg -y -framerate 30 -pattern_type glob -i 'tmp/*.png' -c:v libx264 -pix_fmt yuv420p -s 800x800 tmp/galton.mp4")

# mp4 to gif
# ffmpeg -i galton.mp4 -filter_complex 'fps=30,scale=800:-1:flags=lanczos,split [o1] [o2];[o1] palettegen [p]; [o2] fifo [o3];[o3] [p] paletteuse' out.gif

# gifsicle -O99 -o out2.gif -k 16 out.gif
