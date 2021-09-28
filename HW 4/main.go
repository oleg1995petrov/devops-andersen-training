package main

import (
	"fmt"
	"log"
	re "regexp"
	"strings"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api"
)

var (
	greeting string = "Hi there 🖐️! I'm a simple but useful bot 🧑‍💻. I was made with ❤️ by @by_ventz.\n\n" +
		"☝️ At the top you can see my commands. Type \"/help\" to see a tip again."
	help_msg string = "Type /git to receive the course repository address.\n" +
		"Type /tasks to see the list with homeworks which are done.\n" +
		"Type /task#, where \"#\" is the number of the homework, to receive " +
		"the link to the folder with the homework done.\n"
	repo_url        string = "https://github.com/oleg1995petrov/devops-andersen-training"
	unknown_cmd_err string = "⁉️ I don't know that command. Type \"/help\" to know right commands."
	noncmd_err      string = "🥱 I only accept several commands but I keep learning.\n" +
		"Type \"/help\" to see a tip."
)

func init() {
	fetch_tasks()
}

func main() {
	bot, err := tgbotapi.NewBotAPI("Your very secret APi key")
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
				fetch_tasks_handler()
				text := "The next tasks are done ✅:\n"
				for i := range tasks {
					if strings.HasPrefix(tasks[i].Name, "HW") {
						hw_num := strings.Fields(tasks[i].Name)[1]
						text += fmt.Sprintf("%d. %s", i+1, fmt.Sprintf("/task%s\n", hw_num))
					}
				}
				text += "Check them out!"
				msg.Text = text
			default:
				pattern := re.MustCompile("/task([0-9]+)")
				if pattern.MatchString(update.Message.Text) {
					fetch_tasks_handler()
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
