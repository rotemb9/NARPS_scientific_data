# Clear workspace
rm(list=ls())

# Define the local path where the data can be found
# you will need to set the correct path whre the RData file with the data is located
input_file_path="DEFINE PATH OF DATA HERE"
input_file_path="/Users/rotembotvinik/Google_Drive/github/NARPS_scientific_data/behav_analysis/"

# load data
input_filename=paste(input_file_path, "behav_data.Rdata",sep="")  
load(file=input_filename)

# missed trials
num_missed_trials=tapply(data$participant_response=="NoResp",data$participant_num,sum)
print(paste("Missed trials across participants: mean = ", round(mean(num_missed_trials),3), ", SD = ", round(sd(num_missed_trials),3), ", range = ", range(num_missed_trials)[1], " - ", range(num_missed_trials)[2], sep=""))

# basic plots of missed trials
num_missed_trials_equal_indifference=tapply(data_equal_indifference$participant_response=="NoResp",data_equal_indifference$participant_num,sum)
barplot(num_missed_trials_equal_indifference, main="Number of missed trials across participants - equal indifference condition", xlab="Participant", ylab="Number of missed trials")
num_missed_trials_equal_range=tapply(data_equal_range$participant_response=="NoResp",data_equal_range$participant_num,sum)
barplot(num_missed_trials_equal_range, main="Number of missed trials across participants - equal range condition", xlab="Participant", ylab="Number of missed trials")

# create accept / reject matrices
# equal indifference
response_matrices_equal_indifference = ggplot(data=data_equal_indifference,aes(x = gain, y=loss)) +
  geom_tile(aes(fill=ordinal_response))
# plot all matrices
response_matrices_equal_indifference + facet_wrap(~ participant_num, nrow = 6, ncol = 9) +
  theme(strip.text.x=element_text(size=12))

# equal range
response_matrices_equal_range = ggplot(data=data_equal_range,aes(x = gain, y=loss)) +
  geom_tile(aes(fill=ordinal_response))
# plot all matrices
response_matrices_equal_range + facet_wrap(~ participant_num, nrow = 6, ncol = 9) +
  theme(strip.text.x=element_text(size=12))