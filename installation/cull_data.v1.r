# functions that will cull data from abundance table and metadata file for a list of ids

data_cull.v1 <- function( data_in=NULL, metadata_in=NULL, cull_list="cull_ids.txt", cull_list_type="file", pass_file_suffix="PASS", culled_file_suffix="CULLED", debug=FALSE){

  # func to import single column list of ids to cull
  import_idList <- function(cull_list){
    id_list <- scan(file=cull_list, what="character", quiet=TRUE, comment.char="#")
    return(id_list)
  }

  # func to import the data; columns are samples, rows are categories
  import_data <- function(data_in){
    data_matrix <- data.matrix(read.table(data_in, row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))
    return(data_matrix)
  }

  # func to import metadata; columns are metadata conditions, rows are samples
  import_metadata <- function(metadata_in){
    metadata_matrix <- as.matrix( # Load the metadata table (same if you use one or all columns)
                                 read.table(
                                            file=metadata_in,row.names=1,header=TRUE,sep="\t",
                                            colClasses = "character", check.names=FALSE,
                                            comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE
                                            )
                                 )   
    
    return(metadata_matrix)
    
    print("NOTE")
  }
  
  if(debug==TRUE){print("RUNNING IN DEBUG MODE")}
  
  # import list of ids to cull
  if( identical(cull_list_type, "r_list") ){
    id_list <- cull_list
  }else if (identical(cull_list_type, "file")){
    id_list <- import_idList(cull_list)
  }else{
    stop("invalid cull_list_type - you can choose \"r_list\" or \"file\"")
  }
    
  # cull data file
  if( is.null(data_in)==FALSE ){
    data_matrix <- import_data(data_in)
    # file  with data retained
    pass_data_matrix <- data_matrix[ ,!(colnames(data_matrix) %in% id_list)]
    pass_data_file_name = gsub("\\.\\.", "\\.", paste(data_in, ".", pass_file_suffix, ".txt", sep="", collapse="" ))
    if(debug==TRUE){ test1 <<- pass_data_matrix; print(pass_data_file_name) }
    write.table(pass_data_matrix, file=pass_data_file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
    # file with data culled
    culled_data_matrix <- data_matrix[ ,(colnames(data_matrix) %in% id_list)]
    culled_data_file_name = gsub("\\.\\.", "\\.", paste(data_in, ".", culled_file_suffix, ".txt", sep="", collapse="" ))
    if(debug==TRUE){ test2 <<- culled_data_matrix; print(culled_data_file_name) }
    write.table(culled_data_matrix, file=culled_data_file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
  }
  
  # cull metadata file
  if( is.null(metadata_in)==FALSE ){
    # file with metadata retained
    metadata_matrix <- import_metadata(metadata_in)
    pass_metadata_matrix <- metadata_matrix[!(rownames(metadata_matrix ) %in% id_list),]


    if(debug==TRUE){
      metadata_matrix.test <<- metadata_matrix
      id_list.test <<- id_list
                  }
    
    pass_metadata_file_name = gsub("\\.\\.", "\\.", paste(metadata_in, ".", pass_file_suffix, ".txt", sep="", collapse="" ))
    write.table(pass_metadata_matrix, file=pass_metadata_file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
    # file with metadata culled
    culled_metadata_matrix <- metadata_matrix[(rownames(metadata_matrix ) %in% id_list),]
    culled_metadata_file_name = gsub("\\.\\.", "\\.", paste(metadata_in, ".", culled_file_suffix, ".txt", sep="", collapse="" ))
    write.table(culled_metadata_matrix, file=culled_metadata_file_name, sep="\t", col.names = NA, row.names = TRUE, quote = FALSE, eol="\n")
  }

  print("NOTE")
  
}




# NOTE

# http://stackoverflow.com/questions/9805507/deselecting-a-column-by-name-r
# dd[ ,!(colnames(dd) %in% c("A", "B"))] # remove multiple
# dd[ , names(dd) != "A"] # remove single
  



                                       
