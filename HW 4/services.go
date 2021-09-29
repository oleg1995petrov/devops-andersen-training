package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	re "regexp"
	"strings"
	"time"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api"
)

var (
	api_url    string = "https://api.github.com/repos/oleg1995petrov/devops-andersen-training/contents"
	repo_url   string = "https://github.com/oleg1995petrov/devops-andersen-training"
	tasks      []HW
	updated_at time.Time
	greeting   string = "Hi there 🖐️! I'm a simple but useful bot 🧑‍💻. I was made with ❤️ by @by_ventz.\n\n" +
		"☝️ At the top you can see my commands. Type \"/help\" to see a tip again."
	help_msg string = "Type /git to receive the course repository address.\n" +
		"Type /tasks to see a list with tasks done.\n" +
		"Type /task#, where \"#\" is a task number, to receive " +
		"the link to the folder with the task done.\n"
	unknown_cmd_err string = "⁉️ I don't know that command. Type \"/help\" to know right commands."
	task_err        string = "⛔️ No no no! Homework isn't done yet."
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
	resp, resp_err := http.Get(api_url)
	if resp_err != nil {
		log.Fatal(resp_err)
	}
	if resp.Body != nil {
		defer resp.Body.Close()
		decode_err := json.NewDecoder(resp.Body).Decode(&tasks)
		if decode_err != nil {
			log.Fatal(decode_err)
		}
		updated_at = time.Now()
	}
}

func generate_response_from_cmd(update tgbotapi.Update) string {
	var response string

	switch update.Message.Command() {
	case "start":
		response = greeting
	case "help":
		response = help_msg
	case "git":
		response = repo_url
	case "tasks":
		fetch_tasks_handler()
		response = "The next tasks are done ✅:\n"
		for i := range tasks {
			if strings.HasPrefix(tasks[i].Name, "HW") {
				task_num := strings.Fields(tasks[i].Name)[1]
				response += fmt.Sprintf("%d. %s", i+1, fmt.Sprintf("/task%s\n", task_num))
			}
		}
		response += "Check them out!"
	default:
		pattern := re.MustCompile("/task([0-9]+)")
		if pattern.MatchString(update.Message.Text) {
			fetch_tasks_handler()
			task_num := pattern.FindStringSubmatch(update.Message.Text)[1]
			response = get_task_url(task_num)
		} else {
			response = unknown_cmd_err
		}
	}
	return response
}

func get_task_url(task_num string) string {
	url := ""
	task_name := fmt.Sprintf("HW %s", task_num)
	for i := range tasks {
		if tasks[i].Name == task_name {
			url = tasks[i].Url
			break
		}
	}
	if url == "" {
		url = task_err
	}
	return url
}
