package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

var router *gin.Engine

func index(c *gin.Context) {
	c.String(
		http.StatusOK,
		"Hello World 2",
	)
}

func main() {
	gin.SetMode(gin.ReleaseMode)
	router = gin.Default()
	router.GET("/", index)
	router_err := router.Run()

	if router_err != nil {
		log.Fatal()
	}
}
