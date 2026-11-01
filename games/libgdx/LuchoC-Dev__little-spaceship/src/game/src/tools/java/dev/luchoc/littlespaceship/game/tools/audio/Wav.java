package dev.luchoc.littlespaceship.game.tools.audio;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * A minimal mono 16-bit PCM WAV writer, with no dependency on {@code javax.sound} or any other
 * library — this is design-time tooling, run by hand to produce the files {@code game} ships, and
 * every dependency it pulls in is a dependency that has to be re-checked for TeaVM even though it
 * never runs there. Writing 44 header bytes by hand costs less than that check.
 *
 * @see GenerateAudio the tool that calls this
 */
final class Wav {

    private static final int SAMPLE_RATE = 44100;
    private static final int CHANNELS = 1;
    private static final int BITS_PER_SAMPLE = 16;

    private Wav() {
    }

    /**
     * Writes {@code samples} (each expected in {@code [-1, 1]}, clamped otherwise) as a mono 16-bit
     * PCM WAV file at {@code path}, creating parent directories as needed.
     */
    static void write(Path path, float[] samples) throws IOException {
        Files.createDirectories(path.getParent());
        int dataSize = samples.length * 2;
        ByteArrayOutputStream buffer = new ByteArrayOutputStream(44 + dataSize);
        writeHeader(buffer, dataSize);
        ByteBuffer sampleBuffer = ByteBuffer.allocate(dataSize).order(ByteOrder.LITTLE_ENDIAN);
        for (float sample : samples) {
            float clamped = Math.max(-1f, Math.min(1f, sample));
            sampleBuffer.putShort((short) Math.round(clamped * 32767f));
        }
        buffer.write(sampleBuffer.array());
        Files.write(path, buffer.toByteArray());
    }

    private static void writeHeader(OutputStream out, int dataSize) throws IOException {
        int byteRate = SAMPLE_RATE * CHANNELS * BITS_PER_SAMPLE / 8;
        short blockAlign = (short) (CHANNELS * BITS_PER_SAMPLE / 8);
        ByteBuffer header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN);
        header.put("RIFF".getBytes());
        header.putInt(36 + dataSize);
        header.put("WAVE".getBytes());
        header.put("fmt ".getBytes());
        header.putInt(16); // fmt chunk size
        header.putShort((short) 1); // PCM
        header.putShort((short) CHANNELS);
        header.putInt(SAMPLE_RATE);
        header.putInt(byteRate);
        header.putShort(blockAlign);
        header.putShort((short) BITS_PER_SAMPLE);
        header.put("data".getBytes());
        header.putInt(dataSize);
        out.write(header.array());
    }

    static int sampleRate() {
        return SAMPLE_RATE;
    }
}
