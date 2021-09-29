package main

import (
	"log"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api"
)

var noncmd_err string = "🥱 I only accept several commands but I keep learning.\n" +
	"Type \"/help\" to see a tip."

func init() {
	fetch_tasks()
}

func main() {
	bot, bot_err := tgbotapi.NewBotAPI("Your very secret API key")
	if bot_err != nil {
		log.Panic(bot_err)
	}

	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60

	updates, updates_err := bot.GetUpdatesChan(u)
	if updates_err != nil {
		log.Panic(updates_err)
	}

	for update := range updates {
		if update.Message == nil {
			continue
		}

		msg := tgbotapi.NewMessage(update.Message.Chat.ID, "")
		if update.Message.IsCommand() {
			msg.Text = generate_response_from_cmd(update)
			bot.Send(msg)
		} else {
			msg.Text = noncmd_err
			bot.Send(msg)
		}
	}
}
