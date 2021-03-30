#' @export
#' @title Convert documents to pdf
#' @description Convert documents to pdf using Libre Office. It
#' supports very well "Microsoft PowerPoint" to PDF. "Microsoft Word"
#' can also be converted but some Word features are not supported
#' such as sections.
#' @param input,output file input and optional file output. If output
#' file is not provided, the value will be the value of input file with
#' extension "pdf".
#' @param use_docx2pdf if TRUE (and if 'Microsoft Word' executable
#' can be found as well as 'docx2pdf'), docx2pdf will be used to
#' convert 'Word' documents to PDF. This makes it possible to have a
#' PDF identical to the 'Word' display whereas with 'LibreOffice', this
#' is not always the case.
#' @section Ubuntu platforms:
#' On some Ubuntu platforms, 'LibreOffice' require to add in
#' the environment variable `LD_LIBRARY_PATH` the following path:
#' `/usr/lib/libreoffice/program` (you should see the message
#' "libreglo.so cannot open shared object file" if it is the case). This
#' can be done with R
#' command `Sys.setenv(LD_LIBRARY_PATH = "/usr/lib/libreoffice/program/")`
#' @examples
#' library(locatexec)
#' if (exec_available("libreoffice")) {
#'
#'   out_pptx <- tempfile(fileext = ".pdf")
#'   file <- system.file(package = "doconv",
#'     "doc-examples/example.pptx")
#'
#'   to_pdf(input = file, output = out_pptx)
#'
#'   out_docx <- tempfile(fileext = ".pdf")
#'   file <- system.file(package = "doconv",
#'     "doc-examples/example.docx")
#'
#'   to_pdf(input = file, output = out_docx)
#'
#' }
#' @return the name of the produced pdf (the same value as `output`),
#' invisibly.
#' @importFrom locatexec libreoffice_exec
#' @importFrom locatexec is_windows
to_pdf <- function(input, output = gsub("\\.[[:alnum:]]+$", ".pdf", input),
                   use_docx2pdf = FALSE) {
  if (!file.exists(input)) {
    stop("input does not exist")
  }
  input <- absolute_path(input)

  init_working_directory(force = TRUE)
  default_root <- working_directory()

  file.copy(
    from = input,
    to = default_root,
    overwrite = TRUE
  )

  if(grepl("\\.(doc|docx)$", input) && use_docx2pdf && exec_available("word") && docx2pdf_available()){
    docx2pdf(input = input, output = output)
  } else {
    file_set_origin <- list.files(default_root, full.names = TRUE)
    suppressWarnings(
      info <- try(
        system2(
          libreoffice_exec(),
          args = c("--headless",
                   if(!is_windows()) "\"-env:UserInstallation=file:///tmp/LibreOffice_Conversion_${USER}\"",
                   "--convert-to", "pdf:writer_pdf_Export",
                   "--outdir", shQuote(default_root, type = "cmd"),
                   shQuote(input, type = "cmd")),
          stderr = TRUE, stdout = TRUE), silent = TRUE)
    )
    out <- !1 %in% attr(info, "status")
    if(!out) {
      stop(paste0(info, collapse = "\n"))
    }

    file_set_new <- list.files(default_root, full.names = TRUE)
    file_set_new <- setdiff(file_set_new, file_set_origin)
    success <- file.copy(from = file_set_new, to = output, overwrite = TRUE)
    unlink(file.path(default_root, basename(input)), force = TRUE)
    unlink(file_set_new, force = TRUE)
    if (any(!success)) {
      stop("could not convert ", shQuote(input))
    }
  }

  invisible(output)
}
