package models

import "encoding/xml"

// MoodleQuiz представляет корневой элемент Moodle XML
type MoodleQuiz struct {
	XMLName   xml.Name          `xml:"quiz"`
	Questions []MoodleQuestion  `xml:"question"`
}

// MoodleQuestion представляет вопрос в формате Moodle XML
type MoodleQuestion struct {
	Type                      string                     `xml:"type,attr"`
	Name                      MoodleText                 `xml:"name"`
	QuestionText              MoodleText                 `xml:"questiontext"`
	GeneralFeedback           MoodleText                 `xml:"generalfeedback"`
	DefaultGrade              string                     `xml:"defaultgrade"`
	Penalty                   string                     `xml:"penalty"`
	Hidden                    string                     `xml:"hidden"`
	IDNumber                  string                     `xml:"idnumber"`
	Single                    string                     `xml:"single"`
	ShuffleAnswers            string                     `xml:"shuffleanswers"`
	AnswerNumbering           string                     `xml:"answernumbering"`
	ShowStandardInstruction   string                     `xml:"showstandardinstruction"`
	CorrectFeedback           MoodleText                 `xml:"correctfeedback"`
	PartiallyCorrectFeedback  MoodleText                 `xml:"partiallycorrectfeedback"`
	IncorrectFeedback         MoodleText                 `xml:"incorrectfeedback"`
	Answers                   []MoodleAnswer             `xml:"answer"`
}

// MoodleText представляет текстовый элемент с форматом
type MoodleText struct {
	Format string `xml:"format,attr"`
	Text   string `xml:"text"`
}

// MoodleAnswer представляет вариант ответа в Moodle XML
type MoodleAnswer struct {
	Fraction string     `xml:"fraction,attr"`
	Format   string     `xml:"format,attr"`
	Text     string     `xml:"text"`
	Feedback MoodleText `xml:"feedback"`
}