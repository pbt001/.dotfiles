;;; setup-projectile.el --- Projectile -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;------------------------------------------------------------------------------
;; `counsel-projectile':
;;------------------------------------------------------------------------------
(use-package counsel-projectile
  :after (counsel
          projectile)
  :commands (counsel-projectile
             counsel-projectile-find-file
             counsel-projectile-find-dir
             counsel-projectile-switch-to-buffer
             counsel-projectile-grep
             counsel-projectile-ag
             counsel-projectile-switch-project))

;;------------------------------------------------------------------------------
;; `projectile':
;;------------------------------------------------------------------------------
(use-package projectile
  :hook (emacs-startup . projectile-mode)
  :init
  (setq projectile-sort-order 'recentf
        projectile-enable-caching (not noninteractive)
        projectile-indexing-method 'alien
        projectile-globally-ignored-files '(".DS_Store" "TAGS")
        projectile-globally-ignored-directories '("~/.emacs.d/elpa")
        projectile-globally-ignored-file-suffixes '(".elc" ".pyc" ".o"))
  :config
  ;; Don't consider my home dir as a project
  (add-to-list 'projectile-ignored-projects `,(concat (getenv "HOME") "/"))

  ;; Default rg arguments
  ;; https://github.com/BurntSushi/ripgrep
  (defconst api--rg-arguments
    `("--no-ignore-vcs"          ;Ignore files/dirs ONLY from `.ignore'
      "--line-number"            ;Line numbers
      "--smart-case"
      "--follow"                 ;Follow symlinks
      "--max-columns" "150"      ;Emacs doesn't handle long line lengths very well
      "--ignore-file" ,(expand-file-name ".ignore" (getenv "HOME")))
    "Default rg arguments used in the functions in `counsel' and `projectile' packages.")

  (defun api*advice-projectile-use-rg ()
    "Always use `rg' for getting a list of all files in the project."
    (let* ((prj-user-ignore-name (expand-file-name
                                  (concat ".ignore." user-login-name)
                                  (projectile-project-root)))
           (prj-user-ignore (when (file-exists-p prj-user-ignore-name)
                              (concat "--ignore-file " prj-user-ignore-name))))
      (mapconcat #'shell-quote-argument
                 (if prj-user-ignore
                     (append '("rg")
                             api--rg-arguments
                             `(,prj-user-ignore)
                             '("--null" ;Output null separated results
                               ;; Get names of all the to-be-searched files,
                               ;; same as the "-g ''" argument in ag.
                               "--files"))
                   (append '("rg")
                           api--rg-arguments
                           '("--null"
                             "--files")))
                 " ")))

  (if (executable-find "rg")
      (advice-add 'projectile-get-ext-command :override #'api*advice-projectile-use-rg))

  (after! ivy
    (setq projectile-completion-system 'ivy))

  ;; (after! helm
  ;;   (defvar helm-projectile-find-file-map (make-sparse-keymap))
  ;;   (require 'helm-projectile)
  ;;   (set-keymap-parent helm-projectile-find-file-map helm-map))

  (add-hook 'dired-before-readin-hook #'projectile-track-known-projects-find-file-hook))

;;------------------------------------------------------------------------------
;; `nameframe-projectile':
;;------------------------------------------------------------------------------
(use-package nameframe-projectile
  :after (nameframe projectile)
  :hook (emacs-startup . nameframe-projectile-mode)
  :config
  (require 'nameframe-projectile))

(provide 'setup-projectile)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; setup-projectile.el ends here
