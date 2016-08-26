
(in-package :cl-fm)
(defconstant COL-ID 0)
(defconstant COL-NAME 1)
(defconstant COL-SIZE 2)
(defconstant COL-DATE 3)
(defconstant COL-Q 4)
(defconstant COL-DIR 5)


(defun create-column (number title &key (custom nil) (align nil) (scale 0.75) (expand nil))
  "helper - create a single column with a text renderer"
  (let* ((renderer (gtk-cell-renderer-text-new))
	 (column (gtk-tree-view-column-new-with-attributes title renderer "text" number)))
   (setf (gtk-cell-renderer-is-expander renderer) t)
    (setf (gtk-cell-renderer-text-scale-set renderer) t) ;allow text to scale
    (setf (gtk-cell-renderer-text-scale renderer) scale)   ;scale a little smaller
    (when align (setf (gtk-cell-renderer-xalign renderer) align)) ;align data within cell
    (when custom (gtk-tree-view-column-set-cell-data-func ;custom renderer data
		  column renderer custom))
    (gtk-tree-view-column-set-sort-column-id column number)
    (gtk-tree-view-column-set-reorderable column t)
    (when expand (gtk-tree-view-column-set-expand column t))
    column))

(defun create-columns ()
  ;; Create columns
  (list (create-column COL-ID "#" :align 1.0 :custom #'custom-id)
	(create-column COL-NAME "Filename" :custom #'custom-name :expand t
		       )
	(create-column COL-SIZE "Size" :align 1.0 :custom #'custom-size)
	(create-column COL-DATE "Mod" :custom #'custom-date)
	(create-column COL-Q    "Q" )
	(create-column COL-DIR "DIR" :custom #'custom-id)))

(defun create-model ()
  (let ((model
	 (make-instance 'gtk-tree-store
			              ;;; ID        NAME       SIZE    DATE    Q      DIR
			:column-types '("guint" "gchararray" "gint64" "guint" "guint" "guint"))))
    (g-signal-connect model "row-deleted" #'on-row-deleted)
    (g-signal-connect model "row-inserted" #'on-row-inserted)
    (g-signal-connect model "row-changed" #'on-row-changed)
    model))

(defun model-refill (store path &key (include-dirs t))
  "clear gtk store and reload store with data from filesystem"
  (gtk-tree-store-clear store)
  ;; First load directories, then files...
  (let ((i 1))
    (if include-dirs
	(loop for file-name in (cl-fad:list-directory path)
	   do
	     (when (cl-fad:directory-pathname-p file-name)
	       (gtk-tree-store-set store (gtk-tree-store-append store nil)
				   i          ;ID
				   (file-namestring (string-right-trim "/" (namestring file-name) )) ;NAME
				   -1         ;SIZE
				   0          ;DATE
				   #xf        ;Q
				   1
				   )
	       (incf i))))
    (loop for file-name in (cl-fad:list-directory path)
       do
	 (unless (cl-fad:directory-pathname-p file-name)
	   (gtk-tree-store-set store (gtk-tree-store-append store nil)
			       i          ;ID
			       (file-namestring  (namestring file-name) ) ;NAME
			       -1         ;SIZE
			       0          ;DATE
			       #xf        ;Q
			       0
			       )
	   (incf i)))
    ))

(defun model-postprocess (store directory)
  "across all files, update size, date and q"
  (format t "XXXXXXXXXXXXXXXXXXXXXX~%")
  (gtk-tree-model-foreach
   store
   (lambda (model path iter)
     (declare (ignore path))
     (let ((fname (merge-pathnames directory (gtk-tree-model-get-value model iter COL-NAME)))
	   
	   ) ;build full filepath
;
         

;
       
       

       (let ((size (with-open-file (in fname) (file-length in)))
	     (date (file-write-date fname))
	     (q (q-get fname)))	;    (format t "~A \"~A\" ~A ~A ~A ~%" id name size date q)
	 (unless q (setf q #XF))
	 (if (or (< q 0) (> q 15)) (setf q #XF)) ;TODO: handle range check better !!!
	 (gtk-tree-store-set-value model iter COL-SIZE size)
	 (gtk-tree-store-set-value model iter COL-DATE date)
	 (gtk-tree-store-set-value model iter COL-Q q)))
     nil))) ;continue walk


(defun model-set-q (model path iterator directory value )
  "called to modify q in file and model"
  (let ((pathname (merge-pathnames directory
				   (gtk-tree-model-get-value model iterator COL-NAME))))
    (q-set value pathname))
  (gtk-tree-store-set-value model iterator COL-Q value)
;  (gtk-tree-model-row-changed model path iterator )
  )
(defun on-row-changed (model tp iter)
  (format t "~A ROW-CHANGED ~A~%" (get-universal-time) (first (gtk-tree-model-get model iter COL-ID))))
(defun on-row-inserted (model tp iter)
  (format t "~A ROW-INSERTED ~A~%" (get-universal-time) (first (gtk-tree-model-get model iter COL-ID))))
(defun on-row-deleted (model tp)
  (format t "~A ROW-DELETED ~A~%" (get-universal-time) tp ))


