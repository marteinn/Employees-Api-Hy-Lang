#! /usr/bin/env hy
(import [bottle [route run template response request]])
(import [peewee [Model CharField SqliteDatabase]])
(import [playhouse.shortcuts [model_to_dict dict_to_model]])

;; Globals
(setv db (SqliteDatabase "employees.db"))

;; Models
(defclass BaseModel [Model]
  (defclass Meta []
    (setv database db)))

(defclass Employee [BaseModel]
  (setv email (CharField :unique True))
  (setv company (CharField)))

;; Helpers
(defn response-data [body]
  {"data" body})

(defn set-status [status]
  (setv response.status status))

(defn response-ok [body]
  (set-status 200)
  (response-data body))

(defn response-created [body]
  (set-status 201)
  (response-data body))

(defn response-bad-request [body]
  (set-status 400)
  (response-data body))

(defn response-not-found [body]
  (set-status 404)
  (response-data body))

;; Routes
(with-decorator (route "/employees")
  (defn index []
    (response-ok
      (list
        (map
          (fn [x] (model_to_dict x))
          (Employee.select))))))

(with-decorator (route "/employees/<email>")
  (defn detail [email]
    (setv employee
      (first
        (list
          (map
            (fn [x] (model_to_dict x))
            (.where (Employee.select) (= Employee.email email))))))
    (if (= employee None)
      (response-not-found "Employee not found")
      (response-ok employee))))

(with-decorator (route "/employees/<email>" :method "DELETE")
  (defn delete [email]
    (setv status 
      (.execute (.where (Employee.delete) (= Employee.email email))))
      (if (= status 1)
        (response-ok "deleted")
        (response-not-found "employee not found"))))

(with-decorator (route "/employees" :method "POST")
  (defn create []
    (try
      (.save (Employee.create (unpack-mapping request.forms)))
      (except [Exception]
        (response-bad-request "employee already exists"))
      (else
        (response-created "created")))))

(with-decorator (route "/create-local-db")
  (defn create-local-db []
    (do
      (db.create-tables :models [Employee])
      (response-created "database was created"))))

;; Startup
(defn init-app []
  (do
    (db.connect)
    (run :host "localhost" :port 8080)))

(init-app)
