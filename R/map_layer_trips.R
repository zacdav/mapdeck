mapdeckTripsDependency <- function() {
	list(
		createHtmlDependency(
			name = "trips",
			version = "1.0.0",
			src = system.file("htmlwidgets/lib/trips", package = "mapdeck"),
			script = c("trips.js")
		)
	)
}


#' Add Trips
#'
#' The Trips Layer takes an sf object with Z and M attributes and renders
#' it as animated trips
#'
#' @inheritParams add_polygon
#' @param data sf object with XYZM dimensions.
#' @param trail_length length in metres of the trail
#' @param opacity single value in [0,1]
#' @param start_time the minimum timestamp
#' @param end_time the maximum timestamp
#' @param animation_speed
#' @inheritSection add_arc legend
#' @inheritSection add_arc id
#'
#'
#' @examples
#' \donttest{
#'
#'
#' library(gpx)
#' gpx <- system.file("gpx/city_trail.gpx", package = "gpx")
#' sf <- gpx::gpx_sf( gpx, time = "counter" )
#'
#' mapdeck(
#' 	style = mapdeck_style("dark")
#' 	, location = c(145, -37.9)
#' 	, zoom = 8
#' ) %>%
#' 	add_trips(
#' 		data = sf
#' 		, trail_length = 2000
#' 		, animation_speed = 50
#' 		, stroke_colour = "#FFFFFF"
#' 	)
#'
#' }
#'
#' \code{add_trips} supports LINESTRING and MULTILINESTRING sf objects
#'
#' @export
add_trips <- function(
	map,
	data = get_map_data(map),
	stroke_colour = NULL,
	stroke_width = NULL,
	opacity = 0.3,
	palette = "viridis",
	trail_length = 180,
	start_time = get_m_range_start( data ),
	end_time = get_m_range_end( data ),
	animation_speed = 30,
	layer_id = NULL,
	legend = FALSE,
	legend_options = NULL,
	legend_format = NULL
) {

	experimental_layer("trips")

	l <- list()
	l[["stroke_colour"]] <- force( stroke_colour )
	l[["stroke_width"]] <- force( stroke_width )

	l <- resolve_palette( l, palette )
	l <- resolve_legend( l, legend )
	l <- resolve_legend_options( l, legend_options )
	l <- resolve_data( data, l, c("LINESTRING","MULTILINESTRING") )

	#bbox <- init_bbox()
	#update_view <- force( update_view )
	#focus_layer <- force( focus_layer )

	if ( !is.null(l[["data"]]) ) {
		data <- l[["data"]]
		l[["data"]] <- NULL
	}

	# if( !is.null(l[["bbox"]] ) ) {
	# 	bbox <- l[["bbox"]]
	# 	l[["bbox"]] <- NULL
	# }

	layer_id <- layerId(layer_id, "trips")
	# checkHexAlpha( highlight_colour )

	map <- addDependency(map, mapdeckTripsDependency())

	tp <- l[["data_type"]]
	l[["data_type"]] <- NULL

	if ( tp == "sf" ) {
		geometry_column <- c( "geometry" ) ## This is where we woudl also specify 'origin' or 'destination'
		shape <- rcpp_trips_geojson( data, l, geometry_column )
		jsfunc <- "add_trips_geo"
	} else {
		stop("mapdeck - currently only sf objects are supported for the trips layer")
	}

	# js_transitions <- resolve_transitions( transitions, "path" )
	shape[["legend"]] <- resolve_legend_format( shape[["legend"]], legend_format )

	invoke_method(
		map, jsfunc, map_type( map ), shape[["data"]], opacity, layer_id, trail_length,
		start_time, end_time, animation_speed, shape[["legend"]]
	)
}


#' @rdname clear
#' @export
clear_trips <- function( map, layer_id = NULL) {
	layer_id <- layerId(layer_id, "trips")
	invoke_method(map, "md_layer_clear", layer_id, "trips" )
}


get_m_range_start <- function(x) unname( get_m_range(x)[1] )

get_m_range_end <- function(x) unname( get_m_range(x)[2] )

get_m_range <- function( x ) UseMethod("get_m_range")

## TODO error handle if doesn't exist
## TODO get the geometry column from the sf attributes

#' @export
get_m_range.sf <- function( x ) {

	geometry <- attr( x, "sf_column" )
	if( is.null( attr( x[[geometry]], "m_range" ) ) ) {
		stop("mapdeck - m_range attribute not set; please define the start_time and end_time")
	}

	attr( x[[geometry]], "m_range")
}
#' @export
get_m_range.default <- function( x ) stop("mapdeck - only sf objects with ZM attributes are supported for the trips layer")


