package com.application.Gui;

import java.io.IOException;
import javafx.application.Application;
import javafx.scene.image.Image;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class DatabaseGui extends Application {

    @Override
    public void start(Stage primaryStage) throws RuntimeException {
        Parent root = null;
        try {
            root = FXMLLoader.load(getClass().getResource("/com/application/Gui/views/login.fxml"));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        primaryStage.setTitle("Hurtownia Części Samochodowych");
        primaryStage.setScene(new Scene(root));
        primaryStage.getIcons().add(new Image(getClass().getResourceAsStream("/com/application/Gui/imgs/logo.png")));
        primaryStage.show();
    }

    public static void main(String[] args) {launch(args);}
}
