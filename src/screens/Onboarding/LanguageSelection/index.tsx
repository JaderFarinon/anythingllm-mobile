import React, { useState } from "react";
import { ImageBackground, Text, TouchableOpacity, View } from "react-native";
import { useNavigation } from "@react-navigation/native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import SafeView from "@/components/SafeView";
import { setLanguage } from "@/i18n";
import uiStore from "@/store/UIStore";
import { PATHS } from "@/utils/paths";

export default function OnboardingLanguageSelection() {
  const navigation = useNavigation();
  const insets = useSafeAreaInsets();
  const [saving, setSaving] = useState(false);

  const chooseLanguage = async (language: "pt-BR" | "en") => {
    if (saving) return;
    setSaving(true);
    try {
      await setLanguage(language);
      await uiStore.setToStorage("onboarding_language_completed", true);
      navigation.navigate(PATHS.onboarding.welcome as never);
    } catch (error) {
      console.error("Could not save onboarding language", error);
      setSaving(false);
    }
  };

  return (
    <>
      <ImageBackground
        source={require("@/assets/onboarding/bg-blobs.png")}
        style={{ backgroundColor: "#131314", position: "absolute", top: 0, left: 0, width: "100%", height: "100%" }}
      />
      <SafeView
        scrollable={false}
        safeAreaClassNames="bg-transparent"
        containerClassNames="my-auto"
        containerStyle={{ paddingTop: insets.top + 20, paddingBottom: insets.bottom + 20 }}
      >
        <View className="flex flex-col h-full justify-between py-4 px-4">
          <Text className="text-white text-4xl font-bold text-center">NEXO</Text>
          <View className="gap-y-6">
            <View className="gap-y-2">
            <Text className="text-white text-2xl font-bold text-center">
              Escolha o idioma
            </Text>
            <Text className="text-white text-2xl font-bold text-center">
              Choose your language
            </Text>
            <Text className="text-[#B2DDFF] text-center mt-2">
              Você poderá alterar isso depois. / You can change this later.
            </Text>
          </View>

          <View className="gap-y-4">
            <TouchableOpacity
              accessibilityRole="button"
              accessibilityLabel="Português (Brasil)"
              disabled={saving}
              onPress={() => chooseLanguage("pt-BR")}
              className="w-full bg-[--cta-light-blue] rounded-md p-5"
            >
              <Text className="text-[--dark] font-bold text-center text-lg">
                Português (Brasil)
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              accessibilityRole="button"
              accessibilityLabel="English"
              disabled={saving}
              onPress={() => chooseLanguage("en")}
              className="w-full border border-[#B2DDFF] rounded-md p-5"
            >
              <Text className="text-white font-bold text-center text-lg">English</Text>
            </TouchableOpacity>
          </View>
          </View>
          <Text className="text-[#B2DDFF] text-xs text-center">AnythingLLM Based</Text>
        </View>
      </SafeView>
    </>
  );
}
