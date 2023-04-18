CREATE TABLE IF NOT EXISTS duty_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  start_time INT NOT NULL,
  end_time INT,
  duration INT,
  citizenid VARCHAR(50)
);
