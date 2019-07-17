;;; qthelp.el --- Provides help for Qt projects using Qt assistant

;; Copyright (C) 2019 Dawser

;; Author: Dawser <dawser@none.none>
;; Created: 20 Jun 2019
;; Version: 1.0
;; Keywords: c++, qt

;;; Commentary:

;;; This package provides help for Qt projects.  It uses the Qt assistant
;;; application in remote mode and updates it with the queried element.

;;; Code:

(require 'lsp-mode)
;;(require 'browse-url)

(defgroup qthelp nil
  "Group for qthelp")

(defcustom qthelp-online-help nil
  "If t, load online help in browser, otherwise use Qt assistant."
  :group 'qthelp
  :type 'boolean)

(defvar qthelp-process nil
  "Store the process object for Qt assistant.")

(defvar qthelp-frame nil
  "Store eww's frame for qthelp.")


(defun qthelp--open-url (url)
  "Open URL in eww's buffer."
  (if (not (framep qthelp-frame))
    ;; Create a new frame
    (setq qthelp-frame (make-frame)))
  (select-frame qthelp-frame)
  (eww-browse-url url))


(defun qthelp--describe-things-at-point ()
  "Using some internal functions of lsp-mode, we avoid creating a buffer."
  (let ((contents (-some->> (lsp--text-document-position-params)
                            (lsp--make-request "textDocument/hover")
                            (lsp--send-request)
                            (gethash "contents"))))
    (if (and (> (length contents) 0) (and contents (not (equal contents "")) ))
        (progn
          (let ((search-string (gethash "value" (aref contents 0) nil)))
            (if (string-match "Q[[:alnum:]:]+[^ \(]+" search-string)
                (progn
                  (if (eq (match-beginning 0) 0)
                      (string-match "Q[[:alnum:]:]+[^ \(]+" search-string (match-end 0)))
                  (match-string 0 search-string))
              nil)))
      nil)))


;;;###autoload
(defun qthelp ()
  "Show help for the Qt object at point."
  (interactive)
  (let ((query (qthelp--describe-things-at-point)))
    (if query
        (if qthelp-online-help
            (progn
              ;; Split query into class::function if any.
              (let* ((class-function (split-string query "::"))
                     (cls (elt class-function 0))
                     (fnc (elt class-function 1)))
                ;;(browse-url (concat "https://doc.qt.io/qt-5/" (downcase cls) ".html" (if fnc (concat "#" fnc)))))))))))))
                (qthelp--open-url (concat "https://doc.qt.io/qt-5/" (downcase cls) ".html" (if fnc (concat "#" fnc))))))
          (progn
            (unless (process-live-p qthelp-process)
                   (setq qthelp-process (start-process "qthelp" nil "assistant" "-enableRemoteControl")))
            (process-send-string "qthelp" (concat "activateIdentifier " query "\n")))))))

(provide 'qthelp)
;;; qthelp.el ends here
