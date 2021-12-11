package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func Test_index(t *testing.T) {
	w := httptest.NewRecorder()
	router := gin.Default()
	gin.SetMode(gin.TestMode)
	router.GET("/", index)

	t.Run("get data", func(t *testing.T) {
		assert.Equal(t, http.StatusOK, w.Code)
	})
}
