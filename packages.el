;;; packages.el --- Go Layer packages File for Spacemacs
;;
;; Copyright (c) 2012-2017 Sylvain Benner & Contributors
;;
;; Author: Sylvain Benner <sylvain.benner@gmail.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(setq gop-packages
      '(
        company
        (company-go :toggle
                    (configuration-layer/package-usedp 'company))
        flycheck
        (flycheck-gometalinter :toggle
                               (and go-use-gometalinter
                                    (configuration-layer/package-usedp
                                     'flycheck)))
        go-eldoc
        go-mode
        go-guru
        ;; for refactor
        godoctor
        go-fill-struct
        go-impl
        go-rename
        go-tag
        ;; for test
        go-gen-test
        ))


(defun gop/post-init-company ()
  (spacemacs|add-company-hook go-mode))

(defun gop/init-company-go ()
  (use-package company-go
    :defer t
    :init
    (progn
      (setq company-go-show-annotation t)
      (push 'company-go company-backends-go-mode))))

(defun gop/post-init-flycheck ()
  (spacemacs/add-flycheck-hook 'go-mode))

(defun gop/init-go-mode()
  (when (memq window-system '(mac ns x))
    (dolist (var '("GOPATH" "GO15VENDOREXPERIMENT"))
      (unless (getenv var)
        (exec-path-from-shell-copy-env var))))

  (use-package go-mode
    :defer t
    :init
    (progn
      (defun spacemacs//go-set-tab-width ()
        "Set the tab width."
        (setq-local tab-width go-tab-width))
      (add-hook 'go-mode-hook 'spacemacs//go-set-tab-width))
    :config
    (progn
      (add-hook 'before-save-hook 'gofmt-before-save)

      (defun spacemacs/go-run-tests (args)
        (interactive)
        (save-selected-window
          (async-shell-command (concat "go test " args))))

      (defun spacemacs/go-run-package-tests ()
        (interactive)
        (spacemacs/go-run-tests ""))

      (defun spacemacs/go-run-package-tests-nested ()
        (interactive)
        (spacemacs/go-run-tests "./..."))

      (defun spacemacs/go-run-test-current-function ()
        (interactive)
        (if (string-match "_test\\.go" buffer-file-name)
            (let ((test-method (if go-use-gocheck-for-testing
                                   "-check.f"
                                 "-run")))
              (save-excursion
                  (re-search-backward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?[[:alnum:]]+)[ ]+\\)?\\(Test[[:alnum:]_]+\\)(.*)")
                  (spacemacs/go-run-tests (concat test-method "='" (match-string-no-properties 2) "'"))))
          (message "Must be in a _test.go file to run go-run-test-current-function")))

      (defun spacemacs/go-run-test-current-suite ()
        (interactive)
        (if (string-match "_test\.go" buffer-file-name)
            (if go-use-gocheck-for-testing
                (save-excursion
                    (re-search-backward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?\\([[:alnum:]]+\\))[ ]+\\)?Test[[:alnum:]_]+(.*)")
                    (spacemacs/go-run-tests (concat "-check.f='" (match-string-no-properties 2) "'")))
              (message "Gocheck is needed to test the current suite"))
          (message "Must be in a _test.go file to run go-test-current-suite")))

      (defun spacemacs/go-run-main ()
        (interactive)
        (shell-command
          (format "go run %s"
                  (shell-quote-argument (buffer-file-name)))))

      (spacemacs/declare-prefix-for-mode 'go-mode "me" "playground")
      (spacemacs/declare-prefix-for-mode 'go-mode "mg" "goto")
      (spacemacs/declare-prefix-for-mode 'go-mode "mh" "help")
      (spacemacs/declare-prefix-for-mode 'go-mode "mi" "imports")
      (spacemacs/declare-prefix-for-mode 'go-mode "mt" "test")
      (spacemacs/declare-prefix-for-mode 'go-mode "mx" "execute")
      (spacemacs/set-leader-keys-for-major-mode 'go-mode
        "hh" 'godoc-at-point
        "ig" 'go-goto-imports
        "ia" 'go-import-add
        "ir" 'go-remove-unused-imports
        "eb" 'go-play-buffer
        "er" 'go-play-region
        "ed" 'go-download-play
        "xx" 'spacemacs/go-run-main
        "ga" 'ff-find-other-file
        "gc" 'go-coverage
        "tt" 'spacemacs/go-run-test-current-function
        "ts" 'spacemacs/go-run-test-current-suite
        "tp" 'spacemacs/go-run-package-tests
        "tP" 'spacemacs/go-run-package-tests-nested))))

(defun gop/init-go-eldoc()
  (add-hook 'go-mode-hook 'go-eldoc-setup))

(defun gop/init-go-guru()
  (spacemacs/declare-prefix-for-mode 'go-mode "mf" "guru")
  (spacemacs/set-leader-keys-for-major-mode 'go-mode
    "fd" 'go-guru-describe
    "ff" 'go-guru-freevars
    "fi" 'go-guru-implements
    "fc" 'go-guru-peers
    "fr" 'go-guru-referrers
    "fj" 'go-guru-definition
    "fp" 'go-guru-pointsto
    "fs" 'go-guru-callstack
    "fe" 'go-guru-whicherrs
    "f<" 'go-guru-callers
    "f>" 'go-guru-callees
    "fo" 'go-guru-set-scope))

(defun gop/init-go-rename()
  (use-package go-rename
    :defer t
    :init
    (spacemacs/declare-prefix-for-mode 'go-mode "mr" "refactor")
    (spacemacs/set-leader-keys-for-major-mode 'go-mode "rn" 'go-rename)))

(defun gop/init-go-tag()
  (use-package go-tag
    :defer t
    :init
    (spacemacs/declare-prefix-for-mode 'go-mode "mr" "refactor")
    (spacemacs/set-leader-keys-for-major-mode 'go-mode
      "rF" 'go-tag-remove
      "rf" 'go-tag-add)))

(defun gop/init-go-impl()
  (use-package go-impl
    :defer t
    :init (spacemacs/set-leader-keys-for-major-mode 'go-mode
            "ri" 'go-impl)))

(defun gop/init-go-fill-struct ()
  (use-package go-fill-struct
    :defer t
    :init (spacemacs/set-leader-keys-for-major-mode 'go-mode
            "rs" 'go-fill-struct)))

(defun gop/init-godoctor ()
  (use-package godoctor
    :defer t
    :init (spacemacs/set-leader-keys-for-major-mode 'go-mode
            "rd" 'godoctor-godoc
            "re" 'godoctor-extract
            "rn" 'godoctor-rename
            "rt" 'godoctor-toggle)))

(defun gop/init-go-gen-test()
  (use-package go-gen-test
    :defer t
    :init
    (progn
      (spacemacs/declare-prefix-for-mode 'go-mode "mtg" "gen-test")
      (spacemacs/set-leader-keys-for-major-mode 'go-mode
        "tgg" 'go-gen-test-dwim
        "tgf" 'go-gen-test-exported
        "tgF" 'go-gen-test-all))))

(defun gop/init-flycheck-gometalinter()
  (use-package flycheck-gometalinter
    :defer t
    :init
    (add-hook 'go-mode-hook 'spacemacs//go-enable-gometalinter t)))
