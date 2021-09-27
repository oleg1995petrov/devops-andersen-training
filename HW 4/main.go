package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	re "regexp"
	"strings"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api"
)

var (
	greeting string = "Hi there 🧑‍💻! I'm a simple bot & I was made with ❤️ by @by_ventz.\n\n" +
		"☝️ At the top you can see my commands. Type \"/help\" to see a tip again."
	help_msg string = "Type /git to receive the course repository address.\n" +
		"Type /tasks to see the list with homeworks which are done.\n" +
		"Type /task#, where \"#\" is the number of the homework, to receive " +
		"the link to the folder with the homework done.\n"
	api_url         string = "https://api.github.com/repos/oleg1995petrov/devops-andersen-training/contents"
	repo_url        string = "https://github.com/oleg1995petrov/devops-andersen-training"
	hw_err          string = "⛔️ No no no! Homework isn't done yet."
	unknown_cmd_err string = "⁉️ I don't know that command. Type \"/help\" to know right commands."
	noncmd_err      string = "🥱 I only accept several commands but I keep learning.\n" +
		"Type \"/help\" to see a tip."
	tasks           []HW

)

type HW struct {
	Name string `json:"name"`
	Url  string `json:"html_url"`
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

func init() {
	fetch_tasks()
}

func main() {
	bot, err := tgbotapi.NewBotAPI("Your very secret key!")
	if err != nil {
		log.Panic(err)
	}

	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60

	updates, err := bot.GetUpdatesChan(u)
	if err != nil {
		log.Panic(err)
	}

	for update := range updates {
		if update.Message == nil {
			continue
		}

		msg := tgbotapi.NewMessage(update.Message.Chat.ID, "")
		if update.Message.IsCommand() {
			switch update.Message.Command() {
			case "start":
				msg.Text = greeting
			case "help":
				msg.Text = help_msg
			case "git":
				msg.Text = repo_url
			case "tasks":
				fetch_tasks()
				text := "The next tasks are done ✅:\n"
				for i := range tasks {
					if strings.HasPrefix(tasks[i].Name, "HW") {
						hw_num := strings.Fields(tasks[i].Name)[1]
						// hw_num := strings.Split(tasks[i].Name, " ")[1]
						text += fmt.Sprintf("%d. %s", i+1, fmt.Sprintf("/task%s\n", hw_num))
					}
				}
				text += "Check them out!"
				msg.Text = text
			default:
				pattern := re.MustCompile("/task([0-9]+)")
				if pattern.MatchString(update.Message.Text) {
					fetch_tasks()
					hw_num := pattern.FindStringSubmatch(update.Message.Text)[1]
					msg.Text = get_hw_url(hw_num)
				} else {
					msg.Text = unknown_cmd_err
				}
			}
			bot.Send(msg)
		} else {
			msg.Text = noncmd_err
			bot.Send(msg)
		}
	}
}
