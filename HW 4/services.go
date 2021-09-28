package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

var (
	api_url    string = "https://api.github.com/repos/oleg1995petrov/devops-andersen-training/contents"
	tasks      []HW
	updated_at time.Time
	hw_err     string = "⛔️ No no no! Homework isn't done yet."
)

type HW struct {
	Name string `json:"name"`
	Url  string `json:"html_url"`
}

func fetch_tasks_handler() {
	if len(tasks) == 0 {
		fetch_tasks()
	} else {
		now := time.Now().UTC()
		diff := now.Sub(updated_at)
		if diff.Minutes() >= 30 {
			fetch_tasks()
		}
	}
}

func fetch_tasks() {
	resp, err := http.Get(api_url)
	if err != nil {
		log.Fatal(err)
	}
	if resp.Body != nil {
		defer resp.Body.Close()
		err = json.NewDecoder(resp.Body).Decode(&tasks)
		if err != nil {
			log.Fatal(err)
		}
		updated_at = time.Now()
	}
}

func get_hw_url(hw_num string) string {
	url := ""
	hw_name := fmt.Sprintf("HW %s", hw_num)
	for i := range tasks {
		if tasks[i].Name == hw_name {
			url = tasks[i].Url
			break
		}
	}
	if url == "" {
		url = hw_err
	}
	return url
}
