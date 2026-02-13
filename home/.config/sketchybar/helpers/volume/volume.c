// volume - Get/set system volume via CoreAudio
// Usage: volume 50     (set to 50%)
//        volume +5     (increase by 5%)
//        volume -10    (decrease by 10%)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioToolbox.h>

static AudioDeviceID get_default_output(void) {
    AudioObjectPropertyAddress addr = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };
    AudioDeviceID device = kAudioObjectUnknown;
    UInt32 size = sizeof(device);
    OSStatus err = AudioObjectGetPropertyData(
        kAudioObjectSystemObject, &addr, 0, NULL, &size, &device);
    if (err != noErr) {
        fprintf(stderr, "volume: cannot get default output device (%d)\n", err);
        exit(1);
    }
    return device;
}

static float get_volume(AudioDeviceID device) {
    AudioObjectPropertyAddress addr = {
        kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMain
    };
    Float32 volume = 0.0f;
    UInt32 size = sizeof(volume);
    OSStatus err = AudioObjectGetPropertyData(device, &addr, 0, NULL, &size, &volume);
    if (err != noErr) {
        fprintf(stderr, "volume: cannot get volume (%d)\n", err);
        exit(1);
    }
    return volume;
}

static void set_volume(AudioDeviceID device, float volume) {
    if (volume < 0.0f) volume = 0.0f;
    if (volume > 1.0f) volume = 1.0f;

    AudioObjectPropertyAddress addr = {
        kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMain
    };
    Float32 vol = (Float32)volume;
    OSStatus err = AudioObjectSetPropertyData(device, &addr, 0, NULL, sizeof(vol), &vol);
    if (err != noErr) {
        fprintf(stderr, "volume: cannot set volume (%d)\n", err);
        exit(1);
    }
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: volume <percent|+delta|-delta>\n");
        return 1;
    }

    AudioDeviceID device = get_default_output();
    const char *arg = argv[1];

    if (arg[0] == '+' || arg[0] == '-') {
        // Relative adjustment
        float current = get_volume(device) * 100.0f;
        float delta = (float)atof(arg);
        float target = (current + delta) / 100.0f;
        set_volume(device, target);
    } else {
        // Absolute
        float target = (float)atof(arg) / 100.0f;
        set_volume(device, target);
    }

    return 0;
}
